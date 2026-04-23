# AiDrona Project Update & Development Log
**Date:** April 23, 2026
**Status:** Git Push Resolved | Location System Live | AI Switched to Free Tier

## 🚀 Accomplishments

### 1. Git & Repository Security
*   **Resolved Git Push Error**: Fixed the `GH013` Repository Rule Violation caused by sensitive Google Cloud keys being tracked in history.
*   **Secrets Removal**: Safely removed `service-account-key.json` and `.env` from Git history without deleting the local files.
*   **Infrastructure**: Added a comprehensive `.gitignore` to prevent future leaks of `node_modules`, build artifacts, and private keys.

### 2. Geolocator & Tracking
*   **Enhanced Logic**: Implemented robust location fetching in `request_blood_screen.dart` with high-accuracy settings.
*   **User Experience**: 
    *   Added a "Tap to Refresh" feature for location coordinates.
    *   Added a direct shortcut to App Settings if permissions are permanently denied.
    *   Added visual loading indicators for GPS fetching.
*   **Android Optimization**: Explicitly set `minSdk = 21` in `build.gradle.kts` to satisfy modern location plugin requirements.

### 3. AI Integration (Gemini)
*   **Free Tier Migration**: Successfully migrated the backend from **Vertex AI** (which requires billing/payment) to **Google AI Studio** (which is 100% free).
*   **Background Jobs**: Verified the cron job (`radiusExpansion.js`) is correctly set up to automatically process emergency requests in the background every 2 minutes.

---

## 🛠️ Struggles Faced & Solutions

| Struggle | Cause | How I Handled It |
| :--- | :--- | :--- |
| **Blocked Git Push** | Google Cloud keys were committed in the "First Commit." | Used `git rm --cached` and `git commit --amend` to rewrite history and clear the secrets before pushing. |
| **Build SDK Conflicts** | The default `minSdkVersion` was too low for the `geolocator` plugin. | Manually updated the Kotlin build scripts to use SDK 21+ for better plugin compatibility. |
| **AI Authentication (403)** | Vertex AI required an active billing account/credit card. | Proposed and executed a migration to the **Google Generative AI SDK**, allowing you to use Gemini for free without billing. |
| **Parsing Typos** | Characters like `l` vs `I` (India) in the API key caused "Invalid Key" errors. | Used your provided screenshot to visually verify every character and fixed a typo in the `.env` file. |
| **Dotenv Resolution** | Path issues when running diagnostic scripts from the `/scratch` directory. | Corrected the Working Directory (CWD) logic to ensure environment variables load correctly from any folder. |

---

## 📌 Next Steps for You
1.  **Restart Server**: Run `npm run dev` in the root to active the new AI configuration.
2.  **Test Location**: Go to the "Request Blood" screen on your mobile device to see the new interactive location card.
3.  **API Propagation**: Wait about 5-10 minutes for your new AI Studio key to fully activate on Google's global servers.

**Everything is now configured for a smooth, free-of-cost development experience!**
