const express = require('express');
const router = express.Router();
const { getUserNotifications, markNotificationsRead } = require('../db/firestore');

// GET /api/notifications/:uid — Fetch all notifications for user
router.get('/:uid', async (req, res) => {
  try {
    const notifications = await getUserNotifications(req.params.uid);
    // Convert Firestore Timestamps to ISO strings
    const serialized = notifications.map((n) => ({
      ...n,
      created_at: n.created_at?.toDate ? n.created_at.toDate().toISOString() : (n.created_at ?? null),
    }));
    return res.json(serialized);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// POST /api/notifications/:uid/mark-read — Mark all as read
router.post('/:uid/mark-read', async (req, res) => {
  try {
    await markNotificationsRead(req.params.uid);
    return res.json({ message: 'All notifications marked read' });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

module.exports = router;
