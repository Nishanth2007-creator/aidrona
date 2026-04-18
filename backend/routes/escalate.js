const express = require('express');
const router = express.Router();
const { getNearestBloodBank, updateCrisisRequest, createNotification, getCrisisRequest } = require('../db/firestore');

// POST /api/escalate/bank — Escalate to nearest blood bank
router.post('/bank', async (req, res) => {
  try {
    const { crisis_id } = req.body;
    if (!crisis_id) return res.status(400).json({ error: 'crisis_id required' });

    const crisis = await getCrisisRequest(crisis_id);
    if (!crisis) return res.status(404).json({ error: 'Crisis not found' });

    const bank = await getNearestBloodBank(
      crisis.location.latitude,
      crisis.location.longitude,
      crisis.blood_type
    );

    if (!bank) {
      return res.status(404).json({ error: 'No blood bank with stock found nearby' });
    }

    // Mark crisis as escalated
    await updateCrisisRequest(crisis_id, {
      status: 'escalated_to_bank',
      escalated_bank_id: bank.id,
    });

    // Notify requester
    await createNotification({
      user_id: crisis.requester_id,
      type: 'escalation',
      title: 'Blood Bank Contacted',
      body: `${bank.name} has been alerted and is processing your request.`,
      deep_link: '/requests',
    });

    return res.json({
      message: 'Blood bank alerted',
      bank: { id: bank.id, name: bank.name, phone: bank.phone, distance_km: bank.distance_km },
    });
  } catch (err) {
    console.error('escalate/bank error:', err);
    return res.status(500).json({ error: err.message });
  }
});

module.exports = router;
