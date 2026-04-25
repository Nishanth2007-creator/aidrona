const express = require('express');
const router = express.Router();
const {
  createCrisisRequest, getCrisisRequest, updateCrisisRequest,
  getDonorsWithinRadius, createDonorResponse, createNotification, getUser,
  getCrisisRequestsByUser, getDonorResponsesByUser,
} = require('../db/firestore');
const { triageBloodRequest, rankDonors } = require('../ai/gemini');

// POST /api/request/blood — Submit a new blood request
router.post('/blood', async (req, res) => {
  try {
    const { requester_id, blood_type, urgency, lat, lng, contact_phone_numbers = [] } = req.body;
    if (!requester_id || !blood_type || !urgency || lat == null || lng == null) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const hour = new Date().getHours();
    const time_of_day = hour < 6 ? 'night' : hour < 12 ? 'morning' : hour < 18 ? 'afternoon' : 'evening';

    // Step 1: Gemini triage (with fallback)
    const triage = await triageBloodRequest({ blood_type, urgency, location: { lat, lng }, time_of_day });

    // Step 2: Create crisis in Firestore
    const crisis_id = await createCrisisRequest({
      requester_id,
      blood_type,
      urgency,
      lat,
      lng,
      severity_score: triage.severity_score,
      current_radius_km: triage.recommended_radius_km || 5,
      contacts_only: true, // starts contacts-first
    });

    let donors_notified = 0;
    let phase = 'contacts';
    let ranked = [];

    // Step 3: CONTACTS FIRST — find app users who are in contacts
    if (contact_phone_numbers.length > 0) {
      const contactDonors = await getDonorsByPhoneNumbers(contact_phone_numbers, blood_type);

      if (contactDonors.length > 0) {
        const ranking = await rankDonors({
          blood_type,
          urgency_score: triage.severity_score,
          donor_candidates: contactDonors.slice(0, 20),
        });
        ranked = ranking.ranked_donor_ids || [];

        for (const donor_id of ranked.slice(0, 5)) {
          await createDonorResponse({ crisis_id, donor_id });
          await createNotification({
            user_id: donor_id,
            type: 'donor_popup',
            title: 'Blood Request from your Contact',
            body: `Someone in your contacts needs ${blood_type} blood urgently.`,
            deep_link: '/donor/incoming',
            crisis_id,
          });
          donors_notified++;
        }
      }
    }

    // Step 4: FALLBACK — if no contacts found, open to nearby strangers immediately
    if (donors_notified === 0) {
      phase = 'strangers';
      const nearbyDonors = await getDonorsWithinRadius(lat, lng, triage.recommended_radius_km || 5, blood_type);
      const strangers = nearbyDonors.filter(d => d.donor_id !== requester_id);

      if (strangers.length > 0) {
        const ranking = await rankDonors({
          blood_type,
          urgency_score: triage.severity_score,
          donor_candidates: strangers.slice(0, 20),
        });
        ranked = ranking.ranked_donor_ids || [];

        for (const donor_id of ranked.slice(0, 5)) {
          await createDonorResponse({ crisis_id, donor_id });
          await createNotification({
            user_id: donor_id,
            type: 'donor_popup',
            title: 'Emergency Blood Request Nearby',
            body: `Someone needs ${blood_type} blood urgently near you.`,
            deep_link: '/donor/incoming',
            crisis_id,
          });
          donors_notified++;
        }
        await updateCrisisRequest(crisis_id, { contacts_only: false });
      }
    }

    return res.status(201).json({
      crisis_id,
      triage,
      donors_notified,
      phase,
      message: donors_notified === 0 ? 'No donors found' : `Notified ${donors_notified} via ${phase}`,
    });
  } catch (err) {
    console.error('request/blood error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// POST /api/request/match-contacts — Re-match with contact list
router.post('/match-contacts', async (req, res) => {
  try {
    const { crisis_id, contact_uids } = req.body;
    const crisis = await getCrisisRequest(crisis_id);
    if (!crisis) return res.status(404).json({ error: 'Crisis not found' });

    const donors = await getDonorsWithinRadius(
      crisis.location.latitude, crisis.location.longitude,
      crisis.current_radius_km, crisis.blood_type
    );
    const contactDonors = donors.filter((d) => contact_uids.includes(d.donor_id));

    if (contactDonors.length === 0) return res.json({ ranked: [], message: 'No eligible contacts found' });

    const ranking = await rankDonors({
      blood_type: crisis.blood_type,
      urgency_score: crisis.severity_score,
      donor_candidates: contactDonors,
    });

    return res.json({ ranked: ranking.ranked_donor_ids });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// PATCH /api/request/:id/radius — Extend search radius
router.patch('/:id/radius', async (req, res) => {
  try {
    const { new_radius_km } = req.body;
    await updateCrisisRequest(req.params.id, { current_radius_km: new_radius_km });
    return res.json({ message: 'Radius updated', new_radius_km });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// POST /api/request/:id/open — Open to strangers
router.post('/:id/open', async (req, res) => {
  try {
    const crisis = await getCrisisRequest(req.params.id);
    if (!crisis) return res.status(404).json({ error: 'Crisis not found' });

    await updateCrisisRequest(req.params.id, { contacts_only: false });

    const { lat, lng } = req.body;
    const donors = await getDonorsWithinRadius(
      lat || crisis.location.latitude,
      lng || crisis.location.longitude,
      crisis.current_radius_km,
      crisis.blood_type
    );

    // Exclude requester
    const strangers = donors.filter((d) => d.donor_id !== crisis.requester_id);
    const ranking = await rankDonors({
      blood_type: crisis.blood_type,
      urgency_score: crisis.severity_score,
      donor_candidates: strangers.slice(0, 30),
    });

    for (const donor_id of (ranking.ranked_donor_ids || []).slice(0, 10)) {
      await createDonorResponse({ crisis_id: req.params.id, donor_id });
      await createNotification({
        user_id: donor_id,
        type: 'donor_popup',
        title: 'Emergency Blood Request',
        body: `${crisis.blood_type} blood needed urgently nearby`,
        deep_link: '/donor/incoming',
        crisis_id: req.params.id,
      });
    }

    return res.json({ message: 'Opened to strangers', strangers_notified: ranking.ranked_donor_ids?.length ?? 0 });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// GET /api/request/:id
router.get('/:id', async (req, res) => {
  try {
    const crisis = await getCrisisRequest(req.params.id);
    if (!crisis) return res.status(404).json({ error: 'Crisis not found' });
    return res.json(crisis);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// GET /api/request/list?user_id=xxx&type=sent|received
router.get('/list', async (req, res) => {
  try {
    const { user_id, type } = req.query;
    if (!user_id) return res.status(400).json({ error: 'user_id required' });
    if (type === 'received') {
      const responses = await getDonorResponsesByUser(user_id);
      return res.json(responses);
    }
    const crises = await getCrisisRequestsByUser(user_id);
    return res.json(crises);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

module.exports = router;
