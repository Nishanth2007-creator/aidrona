# AIdrona Project Walkthrough

This document summarizes the current state of the AIdrona platform, including recent critical bug fixes and the core system logic.

## 🏁 Project Status: READY
The system is now fully functional for end-to-end testing of the emergency blood request flow.

---

## 🛠️ Recent Critical Fixes

### 1. **Data Normalization (The "Nitin" Fix)**
- **Issue**: Users were not being matched because of inconsistent field naming (`phone` vs `phone_number`).
- **Fix**: All user profiles and donor profiles have been normalized to use `phone_number`. 
- **Migration**: A sync script was run to ensure all existing users are correctly registered as potential donors.

### 2. **Multi-Role Inclusivity**
- **Issue**: Users who registered as "Patients" were excluded from donor matching.
- **Fix**: The system now automatically creates a **Donor Profile** for every user. Everyone can be a requester and everyone can be a life-saver.

### 3. **Smart Blood Compatibility**
- **Issue**: Matching was only looking for exact blood types.
- **Fix**: Implemented a medical compatibility matrix. 
  - **O-** donors are notified for any request.
  - **AB+** patients can receive from anyone.
  - Correct matching for all other types.

### 4. **Radius Expansion & capping**
- **Logic**: Search starts at **5km**.
- **Expansion**: Every 2 minutes, if the request is unfulfilled, the radius grows by **5km**.
- **Cap**: Expansion stops at **20km**. If no donor is found, the requester is notified, and the request is marked as `closed_no_donor`.

---

## 📱 Mobile App Features
- **Real-time UI**: Added background timers (30s) to Home, Requests, and Notifications screens so status changes (like a donor accepting) appear without manual refresh.
- **QR Verification**: Integrated a functional QR scanner for doctors to confirm successful donations.
- **Triage Visualization**: Requests are color-coded based on AI-assigned triage levels.

---

## 📡 Backend Services
- **Gemini AI**: Integrated as the primary triage engine.
- **Firestore**: Used for real-time document sync between mobile devices.
- **Job Scheduler**: Handles the background expansion of search zones.

---

## 💡 How to Test
1. **Start Server**: Ensure the Node.js backend is running.
2. **Start App**: Open the Flutter app on two emulators (or one emulator and one device).
3. **Create Request**: Raise a request on Device A.
4. **Observe**: 
   - Observe Gemini AI triage the request in the server logs.
   - Watch Device B (if nearby or in contacts) receive the notification.
   - Observe the "My Requests" screen on Device A update automatically as the search radius expands.
