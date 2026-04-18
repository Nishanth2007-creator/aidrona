const express = require('express');
const router = express.Router();
const { getAllUsers, getAllBloodBanks, updateBloodBank, getOpenCrisisRequests, updateUser } = require('../db/firestore');
const { generateAdminInsights } = require('../ai/gemini');

// POST /api/admin/insights — Gemini-powered shortage analysis
router.post('/insights', async (req, res) => {
  try {
    const { region, time_window } = req.body;
    const insights = await generateAdminInsights({ region: region || 'India', time_window: time_window || '24h' });
    return res.json(insights);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// GET /api/admin/users — List all users with optional filters
router.get('/users', async (req, res) => {
  try {
    const users = await getAllUsers(req.query);
    return res.json(users);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// PATCH /api/admin/users/:uid/status — Suspend or restore a user
router.patch('/users/:uid/status', async (req, res) => {
  try {
    const { action } = req.body; // 'suspend' or 'restore'
    if (!['suspend', 'restore'].includes(action)) {
      return res.status(400).json({ error: "action must be 'suspend' or 'restore'" });
    }
    await updateUser(req.params.uid, { suspended: action === 'suspend' });
    return res.json({ message: `User ${action}d` });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// GET /api/admin/banks — All blood banks
router.get('/banks', async (req, res) => {
  try {
    const banks = await getAllBloodBanks();
    return res.json(banks);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// PATCH /api/admin/banks/:id/stock — Update blood bank stock
router.patch('/banks/:id/stock', async (req, res) => {
  try {
    const { stock } = req.body; // { 'O+': 5, 'A+': 2, ... }
    await updateBloodBank(req.params.id, { stock });
    return res.json({ message: 'Stock updated' });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// GET /api/admin/crises — Active crises for map view
router.get('/crises', async (req, res) => {
  try {
    const crises = await getOpenCrisisRequests();
    return res.json(crises);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// POST /api/admin/analytics-summary
router.post('/analytics-summary', async (req, res) => {
  try {
    const { period, region } = req.body;
    const insights = await generateAdminInsights({ region: region || 'India', time_window: period || 'monthly' });
    return res.json(insights);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

module.exports = router;
