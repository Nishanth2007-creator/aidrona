# AIdrona: AI-Powered Emergency Blood Coordination Platform

## 🩸 Mission
AIdrona is designed to bridge the critical gap in emergency blood donation by leveraging AI-driven triage, trusted social graphs (contacts-first), and intelligent geo-fencing.

---

## 🛠️ Technology Stack

### **Frontend (Mobile)**
- **Framework**: Flutter (Dart)
- **Platforms**: Android & iOS
- **Key Plugins**: 
  - `geolocator`: High-precision real-time location tracking.
  - `flutter_contacts`: Secure integration with user's phonebook for "Contacts-First" matching.
  - `firebase_messaging`: Instant push notifications for life-saving alerts.
  - `qr_code_scanner`: Secure donor verification for medical professionals.

### **Backend (Infrastructure)**
- **Runtime**: Node.js & Express.js
- **Database**: Google Cloud Firestore (Real-time, scalable NoSQL).
- **Authentication**: Firebase Auth (Secure phone-based and email authentication).
- **Scheduled Tasks**: Node-cron (Handles the dynamic radius expansion logic).

### **AI Core**
- **Engine**: Google Gemini AI (Vertex AI / Generative AI)
- **Role**: 
  - **Emergency Triage**: Analyzes request details to assign urgency levels (1-3).
  - **Dynamic Search**: Adjusts search parameters based on the severity of the crisis.

---

## 🚀 Unique Value Proposition (The "AIdrona Edge")

### **1. Contacts-First Matching (The Trust Factor)**
Statistically, people are 10x more likely to donate blood to someone they know. AIdrona prioritizes notifying the requester's contacts who are on the platform before expanding to the wider community.

### **2. AI-Driven Triage**
Not all blood requests are equal. Gemini AI parses the requester's situation in real-time, ensuring that a critical surgical emergency gets faster and wider visibility than a routine procedure.

### **3. Intelligent Radius Expansion**
To prevent "notification fatigue," the system doesn't blast everyone. 
- **Start**: Localized search (5km).
- **Expansion**: Every 2 minutes, the system expands the radius by 5km.
- **Cap**: Stops at 20km to ensure donors are within a reasonable travel distance.

### **4. Universal Blood Compatibility Engine**
The matching logic isn't just "O+ to O+." It understands medical compatibility (e.g., O- donors are notified for any blood type request, AB+ patients are matched with any donor).

### **5. Doctor-Verified Fulfillment (QR System)**
Ensures the loop is closed. When a donor reaches the hospital, a doctor scans their unique QR code to verify the donation, updating the system and rewarding the donor.

---

## 🔄 End-to-End Workflow

1.  **Request Created**: User inputs blood type and location.
2.  **AI Assessment**: Gemini AI assigns a Triage Level.
3.  **Tier 1 (Instant)**: All phone contacts with compatible blood types are notified.
4.  **Tier 2 (Proximity)**: App users within 5km receive alerts.
5.  **Tier 3 (Expansion)**: If unfulfilled, the search radius grows (+5km) periodically.
6.  **Fulfillment**: Donor accepts -> Live status updates on requester's map -> QR verification at hospital.
7.  **Auto-Closure**: If no donor is found within 20km, the requester is notified, and the search ends to allow for alternative emergency plans.

---

## 📈 Future Roadmap
- **Live Tracking**: Uber-like movement tracking for donors.
- **AI Medical Chatbot**: Answering donor eligibility questions.
- **Donor Rewards**: Gamified impact stats and badges.
