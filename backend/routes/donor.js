const express = require('express');
const router = express.Router();
const {
  getDonorResponseByCrisisAndDonor, updateDonorResponse, updateDonorProfile,
  getDonorProfile, getCrisisRequest, updateCrisisRequest, createNotification, getDonorsWithinRadius, createDonorResponse,
} = require('../db/firestore');
const { rankDonors } = require('../ai/gemini');

// POST /api/donor/verify — Doctor marks donor fit or unfit
router.post('/verify', async (req, res) => {
  try {
    const { donor_id, crisis_id, doctor_verdict, reason } = req.body;
    if (!donor_id || !crisis_id || !doctor_verdict) {
      return res.status(400).json({ error: 'donor_id, crisis_id, doctor_verdict required' });
    }

    const response = await getDonorResponseByCrisisAndDonor(crisis_id, donor_id);
    if (!response) return res.status(404).json({ error: 'Donor response not found' });

    if (doctor_verdict === 'fit') {
      await updateDonorResponse(response.id, { status: 'accepted', doctor_verified: true });
      await updateCrisisRequest(crisis_id, { status: 'fulfilled' });
      return res.json({ message: 'Donor verified as fit. Donation confirmed.' });
    }

    if (doctor_verdict === 'unfit') {
      // Penalise fitness score
      const profile = await getDonorProfile(donor_id);
      const penalisedScore = Math.max(0, (profile?.fitness_score ?? 50) - 10);
      const doctorUnfitCount = (profile?.doctor_unfit_count ?? 0) + 1;

      await updateDonorProfile(donor_id, {
        fitness_score: penalisedScore,
        is_eligible: penalisedScore >= 40,
        doctor_unfit_count: doctorUnfitCount,
      });

      await updateDonorResponse(response.id, {
        status: 'unfit_on_arrival',
        doctor_verified: true,
        doctor_notes: reason || '',
      });

      // Re-trigger donor search
      const crisis = await getCrisisRequest(crisis_id);
      if (crisis) {
        const donors = await getDonorsWithinRadius(
          crisis.location.latitude, crisis.location.longitude,
          crisis.current_radius_km, crisis.blood_type
        );
        // Exclude the unfit donor
        const remaining = donors.filter((d) => d.donor_id !== donor_id);
        if (remaining.length > 0) {
          const ranking = await rankDonors({
            blood_type: crisis.blood_type,
            urgency_score: crisis.severity_score,
            donor_candidates: remaining.slice(0, 10),
          });
          for (const did of (ranking.ranked_donor_ids || []).slice(0, 3)) {
            // Prevent duplicate notifications
            const existing = await getDonorResponseByCrisisAndDonor(crisis_id, did);
            if (existing) continue;

            await createDonorResponse({ crisis_id, donor_id: did });
            await createNotification({
              user_id: did,
              type: 'donor_popup',
              title: 'Blood Request Still Active',
              body: `${crisis.blood_type} blood still needed urgently nearby`,
              deep_link: '/donor/incoming',
              crisis_id,
            });
          }
        }
        
        // Notify requester that donor was unfit
        await createNotification({
          user_id: crisis.requester_id,
          type: 'request_update',
          title: 'Donor Found Unfit',
          body: 'The donor who accepted your request was found ineligible after a medical check. We are searching for new donors.',
          deep_link: '/requests',
        });
      }

      return res.json({ message: 'Donor marked unfit, score penalised, search re-triggered', new_score: penalisedScore });
    }

    return res.status(400).json({ error: "doctor_verdict must be 'fit' or 'unfit'" });
  } catch (err) {
    console.error('donor/verify error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// GET /api/donor/profile/:uid
router.get('/profile/:uid', async (req, res) => {
  try {
    const profile = await getDonorProfile(req.params.uid);
    if (!profile) return res.status(404).json({ error: 'Profile not found' });
    return res.json(profile);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

module.exports = router;
