const express = require('express');
const router = express.Router();
const { createUser, createDonorProfile, getUser, updateUser, getDoctor } = require('../db/firestore');
const { evaluateDonorFitness } = require('../ai/gemini');

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { uid, name, phone, blood_type, lat, lng, fcm_token, role, emergency_contact_name, emergency_contact_phone } = req.body;
    if (!uid || !name || !phone || !blood_type) {
      return res.status(400).json({ error: 'uid, name, phone, blood_type are required' });
    }

    // Check if already exists
    const existing = await getUser(uid);
    if (existing) return res.status(409).json({ error: 'User already registered' });

    await createUser(uid, { 
      name, 
      phone, 
      blood_type, 
      lat: lat || 0, 
      lng: lng || 0, 
      fcm_token: fcm_token || '', 
      role: role || 'patient',
      emergency_contact_name: emergency_contact_name || '',
      emergency_contact_phone: emergency_contact_phone || ''
    });

    // Create an initial donor profile with a default fitness score
    const initialFitness = await evaluateDonorFitness({
      hemoglobin: 13.5,
      last_donation_days: 999,
      donation_count: 0,
      conditions: [],
      medications: [],
      doctor_unfit_count: 0,
    });

    await createDonorProfile(uid, { ...initialFitness, blood_type });

    return res.status(201).json({ message: 'User registered', fitness: initialFitness });
  } catch (err) {
    console.error('register error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// GET /api/auth/user/:uid
router.get('/user/:uid', async (req, res) => {
  try {
    const user = await getUser(req.params.uid);
    if (!user) return res.status(404).json({ error: 'User not found' });
    return res.json(user);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// PATCH /api/auth/user/:uid — Update user profile fields
router.patch('/user/:uid', async (req, res) => {
  try {
    const allowed = ['donor_active', 'fcm_token', 'lat', 'lng', 'name'];
    const update = {};
    for (const key of allowed) {
      if (req.body[key] !== undefined) update[key] = req.body[key];
    }
    if (Object.keys(update).length === 0) return res.status(400).json({ error: 'No valid fields to update' });
    await updateUser(req.params.uid, update);
    return res.json({ message: 'User updated' });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// DELETE /api/auth/user/:uid — Delete account from Firestore
router.delete('/user/:uid', async (req, res) => {
  try {
    const uid = req.params.uid;
    const { db } = require('../db/firestore');
    await db.collection('users').doc(uid).delete();
    await db.collection('donor_profiles').doc(uid).delete().catch(() => {});
    await db.collection('medical_records').doc(uid).delete().catch(() => {});
    return res.json({ message: 'Account deleted' });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// POST /api/auth/doctor-verify — Verify doctor registration ID
router.post('/doctor-verify', async (req, res) => {
  try {
    const { reg_id } = req.body;
    if (!reg_id) return res.status(400).json({ error: 'reg_id required' });
    const doctor = await getDoctor(reg_id);
    // For demo: accept any reg_id starting with 'DR-' even if not in DB
    if (!doctor && !reg_id.toUpperCase().startsWith('DR-')) {
      return res.status(404).json({ error: 'Doctor not registered in system' });
    }
    return res.json({ verified: true, doctor: doctor || { reg_id, name: 'Verified Doctor' } });
  } catch (err) {
    console.error('doctor-verify error:', err);
    return res.status(500).json({ error: 'Firestore error: ' + err.message });
  }
});

module.exports = router;
