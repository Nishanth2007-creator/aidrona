const admin = require('firebase-admin');
const path = require('path');

let serviceAccount;

if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
  try {
    const rawJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON.trim();
    const parsed = JSON.parse(rawJson);
    
    if (parsed.private_key) {
      // THE NUCLEAR FIX:
      // 1. Convert any literal "\\n" to actual newlines
      // 2. Remove any accidental extra spaces or double newlines
      let key = parsed.private_key.replace(/\\n/g, '\n').trim();
      
      // 3. Ensure it starts/ends with correct tags if it got mangled
      if (!key.includes('-----BEGIN PRIVATE KEY-----')) {
        key = `-----BEGIN PRIVATE KEY-----\n${key}`;
      }
      if (!key.includes('-----END PRIVATE KEY-----')) {
        key = `${key}\n-----END PRIVATE KEY-----\n`;
      }
      
      parsed.private_key = key;
      serviceAccount = parsed;
      console.log('[Firebase] Successfully cleaned and parsed FIREBASE_SERVICE_ACCOUNT_JSON');
    }
  } catch (err) {
    console.error('[Firebase] Critical failure parsing FIREBASE_SERVICE_ACCOUNT_JSON:', err.message);
  }
}

if (!serviceAccount) {
  const keyFile = process.env.GOOGLE_APPLICATION_CREDENTIALS 
    ? path.resolve(__dirname, '..', process.env.GOOGLE_APPLICATION_CREDENTIALS.replace(/"/g, '')) 
    : path.join(__dirname, '..', 'service-account-key.json');
  
  try {
    serviceAccount = require(keyFile);
  } catch (err) {
    console.warn('Could not find service account key file. Ensure FIREBASE_SERVICE_ACCOUNT_JSON or GOOGLE_APPLICATION_CREDENTIALS is set.');
  }
}

if (!admin.apps.length && serviceAccount) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const { getFirestore, GeoPoint, FieldValue, Timestamp } = require('firebase-admin/firestore');
const db = getFirestore('default'); // Use verified 'default' database ID
db.settings({ ignoreUndefinedProperties: true }); // ✅ Fix: Ignore undefined fields to prevent crashes
const Firestore = { Timestamp }; 

// ─── USERS ───────────────────────────────────────────────────
async function createUser(uid, data) {
  await db.collection('users').doc(uid).set({
    ...data,
    location: new GeoPoint(data.lat || 0, data.lng || 0),
    created_at: Firestore.Timestamp.now(),
    role: data.role || 'patient',
  });
}

async function getUser(uid) {
  const snap = await db.collection('users').doc(uid).get();
  return snap.exists ? { id: snap.id, ...snap.data() } : null;
}

async function getUserByPhone(phone) {
  const cleanPhone = phone.replaceAll(' ', '');
  const searchValues = [cleanPhone];
  if (!cleanPhone.startsWith('+')) searchValues.push('+91' + cleanPhone);
  if (cleanPhone.startsWith('+91')) searchValues.push(cleanPhone.replace('+91', ''));

  for (const val of searchValues) {
    // Check 'phone_number' field
    let snap = await db.collection('users').where('phone_number', '==', val).limit(1).get();
    if (!snap.empty) return { id: snap.docs[0].id, ...snap.docs[0].data() };

    // Check 'phone' field (legacy/fallback)
    snap = await db.collection('users').where('phone', '==', val).limit(1).get();
    if (!snap.empty) return { id: snap.docs[0].id, ...snap.docs[0].data() };
  }
  
  return null;
}

async function updateUser(uid, data) {
  await db.collection('users').doc(uid).update(data);
}

// ─── DONOR PROFILES ──────────────────────────────────────────
async function createDonorProfile(uid, data) {
  await db.collection('donor_profiles').doc(uid).set({
    ...data,
    last_donation_date: null,
    donation_count: 0,
    score_updated_at: Firestore.Timestamp.now(),
  });
}

async function updateDonorProfile(uid, data) {
  await db.collection('donor_profiles').doc(uid).update({
    ...data,
    score_updated_at: Firestore.Timestamp.now(),
  });
}

async function getDonorProfile(uid) {
  const snap = await db.collection('donor_profiles').doc(uid).get();
  return snap.exists ? { id: snap.id, ...snap.data() } : null;
}

// ─── DONORS WITHIN RADIUS (bounding box) ─────────────────────
async function getDonorsWithinRadius(lat, lng, radius_km, blood_type) {
  const latDelta = radius_km / 111;
  const lngDelta = radius_km / (111 * Math.cos((lat * Math.PI) / 180));

  // Get eligible donor profiles
  const snap = await db
    .collection('donor_profiles')
    .where('is_eligible', '==', true)
    .orderBy('fitness_score', 'desc')
    .get();

  const donors = [];
  snap.forEach((doc) => {
    const d = doc.data();
    // Filter by compatibility
    if (!isCompatible(d.blood_type, blood_type)) return;

    // Filter by bounding box using denormalised lat/lng
    if (
      d.lat >= lat - latDelta &&
      d.lat <= lat + latDelta &&
      d.lng >= lng - lngDelta &&
      d.lng <= lng + lngDelta
    ) {
      const dist = Math.sqrt(Math.pow((d.lat - lat) * 111, 2) + Math.pow((d.lng - lng) * 111, 2));
      donors.push({ donor_id: doc.id, ...d, distance_km: parseFloat(dist.toFixed(2)) });
    }
  });
  return donors;
}

// ─── MEDICAL RECORDS ─────────────────────────────────────────
async function setMedicalRecord(uid, data) {
  const verifiedAt = new Date();
  const expiresAt = new Date(verifiedAt);
  expiresAt.setMonth(expiresAt.getMonth() + 6);

  await db.collection('medical_records').doc(uid).set({
    ...data,
    verified_at: Firestore.Timestamp.fromDate(verifiedAt),
    expires_at: Firestore.Timestamp.fromDate(expiresAt),
  });
}

async function getMedicalRecord(uid) {
  const snap = await db.collection('medical_records').doc(uid).get();
  return snap.exists ? { id: snap.id, ...snap.data() } : null;
}

// ─── MEDICAL HISTORY LOGS ─────────────────────────────────────
async function addMedicalHistoryLog(data) {
  const ref = db.collection('medical_history_logs').doc();
  await ref.set({ ...data, created_at: Firestore.Timestamp.now() });
  return ref.id;
}

async function getMedicalHistory(uid) {
  const snap = await db
    .collection('medical_history_logs')
    .where('user_id', '==', uid)
    .orderBy('created_at', 'desc')
    .limit(20)
    .get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

// ─── CRISIS REQUESTS ─────────────────────────────────────────
async function createCrisisRequest(data) {
  const ref = db.collection('crisis_requests').doc();
  await ref.set({
    ...data,
    location: new GeoPoint(data.lat, data.lng),
    status: 'open',
    current_radius_km: 5,
    contacts_only: true,
    created_at: Firestore.Timestamp.now(),
  });
  return ref.id;
}

async function getCrisisRequest(id) {
  const snap = await db.collection('crisis_requests').doc(id).get();
  return snap.exists ? { id: snap.id, ...snap.data() } : null;
}

async function updateCrisisRequest(id, data) {
  await db.collection('crisis_requests').doc(id).update(data);
}

async function getOpenCrisisRequests() {
  const snap = await db.collection('crisis_requests').where('status', '==', 'open').get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

// ─── DONOR RESPONSES ─────────────────────────────────────────
async function createDonorResponse(data) {
  const ref = db.collection('donor_responses').doc();
  await ref.set({ ...data, status: 'pending', responded_at: null, created_at: Firestore.Timestamp.now() });
  return ref.id;
}

async function updateDonorResponse(id, data) {
  await db.collection('donor_responses').doc(id).update({ ...data, responded_at: Firestore.Timestamp.now() });
}

async function getDonorResponseByCrisisAndDonor(crisis_id, donor_id) {
  const snap = await db
    .collection('donor_responses')
    .where('crisis_id', '==', crisis_id)
    .where('donor_id', '==', donor_id)
    .limit(1)
    .get();
  if (snap.empty) return null;
  return { id: snap.docs[0].id, ...snap.docs[0].data() };
}

async function getPendingResponsesByCrisis(crisis_id) {
  const snap = await db
    .collection('donor_responses')
    .where('crisis_id', '==', crisis_id)
    .where('status', '==', 'pending')
    .get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

async function getDonorResponsesByCrisis(crisis_id) {
  const snap = await db
    .collection('donor_responses')
    .where('crisis_id', '==', crisis_id)
    .get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

// ─── BLOOD BANKS ─────────────────────────────────────────────
async function getNearestBloodBank(lat, lng, blood_type) {
  const snap = await db.collection('blood_banks').get();
  let nearest = null;
  let minDist = Infinity;

  snap.forEach((doc) => {
    const b = doc.data();
    const stock = b.stock || {};
    if (!stock[blood_type] || stock[blood_type] < 1) return;
    const dist = Math.sqrt(Math.pow((b.location.latitude - lat) * 111, 2) + Math.pow((b.location.longitude - lng) * 111, 2));
    if (dist < minDist) {
      minDist = dist;
      nearest = { id: doc.id, ...b, distance_km: parseFloat(dist.toFixed(2)) };
    }
  });
  return nearest;
}

async function getAllBloodBanks() {
  const snap = await db.collection('blood_banks').get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

async function updateBloodBank(id, data) {
  await db.collection('blood_banks').doc(id).update(data);
}

// ─── NOTIFICATIONS ────────────────────────────────────────────
async function createNotification(data) {
  const ref = db.collection('notifications').doc();
  await ref.set({ ...data, read: false, created_at: Firestore.Timestamp.now() });

  // Attempt FCM push via firebase-admin (graceful fallback)
  if (data.user_id) {
    try {
      const userSnap = await db.collection('users').doc(data.user_id).get();
      const fcmToken = userSnap.data()?.fcm_token;
      if (fcmToken) {
        const admin = require('firebase-admin');
        if (admin.apps && admin.apps.length) {
          await admin.messaging().send({
            token: fcmToken,
            notification: { title: data.title, body: data.body },
            data: { deep_link: data.deep_link || '/', crisis_id: String(data.crisis_id || '') },
            android: { priority: 'high' },
            apns: { payload: { aps: { sound: 'default', badge: 1 } } },
          });
        }
      }
    } catch (e) {
      console.warn('[FCM] Push skipped:', e.message);
    }
  }
  return ref.id;
}

async function getUserNotifications(uid) {
  const snap = await db
    .collection('notifications')
    .where('user_id', '==', uid)
    .orderBy('created_at', 'desc')
    .limit(50)
    .get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

async function markNotificationsRead(uid) {
  const snap = await db.collection('notifications').where('user_id', '==', uid).where('read', '==', false).get();
  const batch = db.batch();
  snap.docs.forEach((d) => batch.update(d.ref, { read: true }));
  await batch.commit();
}

// ─── USERS LIST (admin) ───────────────────────────────────────
async function getAllUsers(filters = {}) {
  let query = db.collection('users');
  if (filters.blood_type) query = query.where('blood_type', '==', filters.blood_type);
  if (filters.role) query = query.where('role', '==', filters.role);
  const snap = await query.limit(200).get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

// Helper to convert a Firestore doc data to plain JSON-safe object
function _serialize(data, id) {
  const result = id ? { id } : {};
  for (const [k, v] of Object.entries(data)) {
    if (v?.toDate) result[k] = v.toDate().toISOString();
    else if (v?.latitude != null && v?.longitude != null) result[k] = { lat: v.latitude, lng: v.longitude };
    else result[k] = v;
  }
  return result;
}

// ─── CRISIS REQUESTS BY USER ──────────────────────────────────
async function getCrisisRequestsByUser(uid) {
  const snap = await db.collection('crisis_requests')
    .where('requester_id', '==', uid)
    .orderBy('created_at', 'desc')
    .limit(30)
    .get();
  return snap.docs.map((d) => _serialize(d.data(), d.id));
}

// ─── DONOR RESPONSES BY USER ──────────────────────────────────
async function getDonorResponsesByUser(uid) {
  const snap = await db.collection('donor_responses')
    .where('donor_id', '==', uid)
    .orderBy('created_at', 'desc')
    .limit(30)
    .get();
  return snap.docs.map((d) => _serialize(d.data(), d.id));
}

// ─── DOCTORS ──────────────────────────────────────────────────
async function getDoctor(regId) {
  const snap = await db.collection('doctors').where('reg_id', '==', regId).limit(1).get();
  if (snap.empty) return null;
  return { id: snap.docs[0].id, ...snap.docs[0].data() };
}

// ─── CONTACTS MATCHING ─────────────────────────────────────────
async function getDonorsByPhoneNumbers(phoneNumbers, requested_blood_type) {
  if (!phoneNumbers || phoneNumbers.length === 0) return [];

  // Firestore 'in' query supports max 30 at a time
  const chunks = [];
  for (let i = 0; i < phoneNumbers.length; i += 30) {
    chunks.push(phoneNumbers.slice(i, i + 30));
  }

  const results = [];
  for (const chunk of chunks) {
    const snapshot = await db.collection('users')
      .where('phone_number', 'in', chunk)
      .get();

    snapshot.docs.forEach(doc => {
      const data = doc.data();
      // Check blood compatibility (Universal Donor logic or exact match)
      if (isCompatible(data.blood_type, requested_blood_type)) {
        results.push({ donor_id: doc.id, ...data });
      }
    });
  }
  return results;
}

// Blood type compatibility helper (Donor -> Recipient)
function isCompatible(donorType, requestedType) {
  if (!donorType || !requestedType) return false;
  const compatibility = {
    'O-': ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'],
    'O+': ['O+', 'A+', 'B+', 'AB+'],
    'A-': ['A-', 'A+', 'AB-', 'AB+'],
    'A+': ['A+', 'AB+'],
    'B-': ['B-', 'B+', 'AB-', 'AB+'],
    'B+': ['B+', 'AB+'],
    'AB-': ['AB-', 'AB+'],
    'AB+': ['AB+'],
  };
  return compatibility[donorType]?.includes(requestedType) ?? false;
}

module.exports = {
  db,
  createUser, getUser, updateUser,
  createDonorProfile, updateDonorProfile, getDonorProfile, getDonorsWithinRadius,
  setMedicalRecord, getMedicalRecord,
  addMedicalHistoryLog, getMedicalHistory,
  createCrisisRequest, getCrisisRequest, updateCrisisRequest, getOpenCrisisRequests,
  getCrisisRequestsByUser, getDonorResponsesByUser,
  createDonorResponse, updateDonorResponse, getDonorResponseByCrisisAndDonor, getPendingResponsesByCrisis, getDonorResponsesByCrisis,
  getNearestBloodBank, getAllBloodBanks, updateBloodBank,
  createNotification, getUserNotifications, markNotificationsRead,
  getAllUsers, getDoctor,
  getDonorsByPhoneNumbers,
  getUserByPhone,
};
