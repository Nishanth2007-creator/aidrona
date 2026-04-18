# AiDrona — Emergency Health Coordination Platform

AI-powered blood donor matching app for India. Connects patients needing blood with verified nearby donors in minutes.

---

## Project Structure

```
AIdrona/
├── backend/               # Node.js + Express API server
│   ├── server.js          # Entry point
│   ├── ai/gemini.js       # 5 Gemini AI functions
│   ├── db/firestore.js    # All Firestore helpers
│   ├── routes/            # auth, request, response, medical, donor, escalate, admin, home
│   ├── jobs/              # Cron job: radius expansion every 2 min
│   └── .env.example       # Environment variable template
├── mobile/                # Flutter app (Android + iOS)
│   └── lib/
│       ├── main.dart
│       ├── theme/         # Dark theme, brand colours
│       ├── screens/       # All patient + doctor screens
│       ├── widgets/       # FitnessRing, EligibilityBadge, GradientButton, etc.
│       ├── services/      # ApiService, AuthService
│       └── providers/     # UserProvider, CrisisProvider
└── firestore.rules        # Firestore security rules
```

---

## Backend Setup

### 1. Install dependencies
```bash
npm install
```

### 2. Firebase / GCP setup
- Create Firebase project at console.firebase.google.com
- Enable: Firestore, Firebase Auth (Phone), Cloud Messaging, Cloud Storage
- Enable Vertex AI in Google Cloud Console (project: `aidrona-prod`, region: `asia-south1`)
- Download service account key → save as `backend/service-account-key.json`

### 3. Create `.env` file
```bash
cp backend/.env.example backend/.env
# Fill in GCP_PROJECT_ID
```

### 4. Run the server
```bash
npm run dev      # Development (requires nodemon: npm i -g nodemon)
npm start        # Production
```

Server runs on `http://localhost:8080`

---

## Flutter App Setup

### Prerequisites
- Flutter SDK ≥ 3.0
- Android Studio / Xcode

### 1. Add Firebase config files
- Android: `mobile/android/app/google-services.json`
- iOS: `mobile/ios/Runner/GoogleService-Info.plist`

### 2. Add fonts
Place Inter font files in `mobile/assets/fonts/`:
- Inter-Regular.ttf, Inter-Medium.ttf, Inter-SemiBold.ttf, Inter-Bold.ttf
(Download from fonts.google.com/specimen/Inter)

### 3. Install dependencies
```bash
cd mobile
flutter pub get
```

### 4. Run app
```bash
flutter run
```

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register user |
| POST | `/api/home/summary` | Home dashboard data |
| POST | `/api/request/blood` | Submit blood request (triggers Gemini triage) |
| POST | `/api/request/match-contacts` | Match donor contacts |
| PATCH | `/api/request/:id/radius` | Extend search radius |
| POST | `/api/request/:id/open` | Open to strangers |
| POST | `/api/response/accept` | Donor accepts |
| POST | `/api/response/decline` | Donor declines |
| POST | `/api/medical/upload` | Upload medical record |
| POST | `/api/medical/update` | Doctor updates record |
| GET | `/api/patient/:uid/summary` | Doctor QR scan result |
| POST | `/api/donor/verify` | Doctor marks fit/unfit |
| POST | `/api/escalate/bank` | Escalate to blood bank |
| GET | `/api/admin/users` | Admin: all users |
| GET | `/api/admin/banks` | Admin: all blood banks |
| GET | `/api/admin/crises` | Admin: active crises |
| POST | `/api/admin/insights` | Gemini shortage analysis |

---

## Gemini AI Functions

| Function | Purpose |
|----------|---------|
| `triageBloodRequest` | Severity score + radius recommendation |
| `evaluateDonorFitness` | Fitness score 0-100 + eligibility |
| `rankDonors` | Ranked donor list for a crisis |
| `checkDisqualifiers` | Medical disqualifier check |
| `generateAdminInsights` | Shortage risk + surge predictions |

---

## Design System

- **Primary**: `#534AB7` (Purple)
- **Teal**: `#0F6E56`
- **Amber**: `#854F0B`
- **Danger**: `#A32D2D`
- **Font**: Inter (700/600/500/400)
- **Mode**: Dark-first

---

## Firestore Collections

`users` · `donor_profiles` · `medical_records` · `medical_history_logs` · `crisis_requests` · `donor_responses` · `blood_banks` · `notifications`

---

*AiDrona — Built for India's blood shortage crisis.*
