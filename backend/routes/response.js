const express = require('express');
const router = express.Router();
const {
  getDonorResponseByCrisisAndDonor, updateDonorResponse, getPendingResponsesByCrisis,
  updateCrisisRequest, createNotification, getCrisisRequest,
} = require('../db/firestore');

// POST /api/response/accept
router.post('/accept', async (req, res) => {
  try {
    const { crisis_id, donor_id } = req.body;
    if (!crisis_id || !donor_id) return res.status(400).json({ error: 'crisis_id, donor_id required' });

    const response = await getDonorResponseByCrisisAndDonor(crisis_id, donor_id);
    if (!response) return res.status(404).json({ error: 'Response record not found' });

    // Mark this donor as accepted
    await updateDonorResponse(response.id, { status: 'accepted', doctor_verified: false });

    // Mark crisis as fulfilled
    await updateCrisisRequest(crisis_id, { status: 'fulfilled', accepted_donor_id: donor_id });

    // Notify all other pending donors that request is filled
    const pending = await getPendingResponsesByCrisis(crisis_id);
    for (const p of pending) {
      if (p.donor_id !== donor_id) {
        await updateDonorResponse(p.id, { status: 'filled' });
        await createNotification({
          user_id: p.donor_id,
          type: 'request_filled',
          title: 'Request Filled',
          body: 'Another donor has already accepted this request. No action needed.',
          deep_link: '/notifications',
        });
      }
    }

    // Notify requester
    const crisis = await getCrisisRequest(crisis_id);
    if (crisis) {
      await createNotification({
        user_id: crisis.requester_id,
        type: 'request_update',
        title: 'Donor Found!',
        body: 'A donor has accepted your request and is on the way.',
        deep_link: '/requests',
      });
    }

    return res.json({ message: 'Donor accepted, others notified' });
  } catch (err) {
    console.error('response/accept error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// POST /api/response/decline
router.post('/decline', async (req, res) => {
  try {
    const { crisis_id, donor_id } = req.body;
    const response = await getDonorResponseByCrisisAndDonor(crisis_id, donor_id);
    if (!response) return res.status(404).json({ error: 'Response record not found' });

    await updateDonorResponse(response.id, { status: 'declined' });
    return res.json({ message: 'Declined' });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

module.exports = router;
