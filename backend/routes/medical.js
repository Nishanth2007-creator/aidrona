const express = require('express');
const router = express.Router();
const {
  setMedicalRecord, getMedicalRecord, getMedicalHistory,
  updateDonorProfile, addMedicalHistoryLog, getDonorProfile, getUser,
} = require('../db/firestore');
const { evaluateDonorFitness, checkDisqualifiers } = require('../ai/gemini');

// POST /api/medical/upload — Patient uploads initial doctor-verified report
router.post('/upload', async (req, res) => {
  try {
    const { user_id, hemoglobin, disqualifiers, medications, doctor_name, conditions } = req.body;
    if (!user_id || hemoglobin == null) return res.status(400).json({ error: 'user_id, hemoglobin required' });

    const donorProfile = await getDonorProfile(user_id);
    const prevScore = donorProfile?.fitness_score ?? 0;

    // Evaluate fitness via Gemini
    const fitness = await evaluateDonorFitness({
      hemoglobin,
      last_donation_days: donorProfile?.last_donation_date
        ? Math.floor((Date.now() - donorProfile.last_donation_date.toDate().getTime()) / 86400000)
        : 999,
      donation_count: donorProfile?.donation_count ?? 0,
      conditions: conditions || disqualifiers || [],
      medications: medications || [],
      doctor_unfit_count: donorProfile?.doctor_unfit_count ?? 0,
    });

    // Save medical record (server-side Admin SDK only)
    await setMedicalRecord(user_id, {
      hemoglobin,
      disqualifiers: fitness.disqualifiers_found || [],
      medications: medications || [],
      doctor_name: doctor_name || '',
    });

    // Update donor profile
    await updateDonorProfile(user_id, {
      fitness_score: fitness.fitness_score,
      is_eligible: fitness.is_eligible,
    });

    return res.json({ fitness_score: fitness.fitness_score, is_eligible: fitness.is_eligible, prev_score: prevScore });
  } catch (err) {
    console.error('medical/upload error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// POST /api/medical/update — Doctor updates patient record
router.post('/update', async (req, res) => {
  try {
    const {
      patient_id, doctor_reg_id, hospital, diagnosis,
      hemoglobin, blood_pressure, new_medications, new_conditions,
    } = req.body;

    if (!patient_id || !doctor_reg_id) return res.status(400).json({ error: 'patient_id, doctor_reg_id required' });

    const donorProfile = await getDonorProfile(patient_id);
    const prevScore = donorProfile?.fitness_score ?? 0;

    // Check disqualifiers via Gemini
    const disqCheck = await checkDisqualifiers({ new_medications, new_conditions, current_hemoglobin: hemoglobin });

    // Re-evaluate full fitness
    const fitness = await evaluateDonorFitness({
      hemoglobin,
      last_donation_days: donorProfile?.last_donation_date
        ? Math.floor((Date.now() - donorProfile.last_donation_date.toDate().getTime()) / 86400000)
        : 999,
      donation_count: donorProfile?.donation_count ?? 0,
      conditions: new_conditions || [],
      medications: new_medications || [],
      doctor_unfit_count: donorProfile?.doctor_unfit_count ?? 0,
    });

    // Write medical record
    await setMedicalRecord(patient_id, {
      hemoglobin,
      disqualifiers: disqCheck.disqualifying_items || [],
      medications: new_medications || [],
      doctor_name: doctor_reg_id,
    });

    // Log the visit
    await addMedicalHistoryLog({
      user_id: patient_id,
      hospital,
      doctor_reg_id,
      diagnosis,
      hemoglobin,
      blood_pressure,
      fitness_score_before: prevScore,
      fitness_score_after: fitness.fitness_score,
      eligibility_changed: donorProfile?.is_eligible !== fitness.is_eligible,
    });

    // Update donor profile
    await updateDonorProfile(patient_id, {
      fitness_score: fitness.fitness_score,
      is_eligible: fitness.is_eligible,
    });

    return res.json({
      fitness_score: fitness.fitness_score,
      is_eligible: fitness.is_eligible,
      prev_score: prevScore,
      disqualifiers: disqCheck,
    });
  } catch (err) {
    console.error('medical/update error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// GET /api/medical/patient/:uid/summary — Doctor scans QR
router.get('/patient/:uid/summary', async (req, res) => {
  try {
    const uid = req.params.uid;
    const [user, medicalRecord, donorProfile, history] = await Promise.all([
      getUser(uid),
      getMedicalRecord(uid),
      getDonorProfile(uid),
      getMedicalHistory(uid),
    ]);
    if (!user) return res.status(404).json({ error: 'Patient not found' });
    return res.json({ user, medical_record: medicalRecord, donor_profile: donorProfile, history: history.slice(0, 3) });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// GET /api/medical/history/:uid
router.get('/history/:uid', async (req, res) => {
  try {
    const history = await getMedicalHistory(req.params.uid);
    return res.json(history);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

module.exports = router;
