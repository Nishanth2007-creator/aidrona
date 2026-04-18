const express = require('express');
const router = express.Router();
const { getUser, getDonorProfile, getMedicalRecord, getUserNotifications, getCrisisRequestsByUser } = require('../db/firestore');

// POST /api/home/summary
router.post('/home/summary', async (req, res) => {
  try {
    const { user_id } = req.body;
    if (!user_id) return res.status(400).json({ error: 'user_id required' });

    const [user, donorProfile, medicalRecord, notifications, recentRequests] = await Promise.all([
      getUser(user_id),
      getDonorProfile(user_id),
      getMedicalRecord(user_id),
      getUserNotifications(user_id),
      getCrisisRequestsByUser(user_id),
    ]);

    if (!user) return res.status(404).json({ error: 'User not found' });

    // Check medical expiry
    let expiry_warning = false;
    if (medicalRecord?.expires_at) {
      const expiry = medicalRecord.expires_at.toDate ? medicalRecord.expires_at.toDate() : new Date(medicalRecord.expires_at);
      const daysToExpiry = Math.floor((expiry - new Date()) / (1000 * 60 * 60 * 24));
      expiry_warning = daysToExpiry <= 30;
    }

    return res.json({
      fitness_status: {
        score: donorProfile?.fitness_score ?? 0,
        is_eligible: donorProfile?.is_eligible ?? false,
        last_donation_date: donorProfile?.last_donation_date ?? null,
      },
      expiry_warning,
      unread_notifications: notifications.filter((n) => !n.read).length,
      recent_activity: recentRequests.slice(0, 3).map((r) => ({
        type: r.status === 'fulfilled' ? 'Donation Request' : 'Blood Request',
        blood_type: r.blood_type,
        status: r.status,
        created_at: r.created_at,
      })),
    });
  } catch (err) {
    console.error('home/summary error:', err);
    return res.status(500).json({ error: err.message });
  }
});

module.exports = router;
