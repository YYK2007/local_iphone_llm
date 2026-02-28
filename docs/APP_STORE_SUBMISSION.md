# App Store Submission Playbook (Qwen iPhone Chat)

Last updated: February 28, 2026

This checklist is tailored to this repository and the current Apple requirements.

## 1) Account and legal prerequisites
- Enroll in Apple Developer Program.
- In App Store Connect, make sure all required agreements are accepted by the Account Holder.
- Decide your seller type:
  - Individual
  - Organization (D-U-N-S required)

## 2) Project readiness (this app)
Before archiving for release:
- Set a production bundle id (not `com.example.*`).
- Set display name and support URL/privacy policy URL in App Store Connect.
- Test cold-start path on real iPhone:
  - open app
  - download model
  - load model
  - send prompt
  - receive response
- Keep model downloads as data files only (`.gguf`), no executable code loading.
- Verify airplane mode behavior after model is already on device.

## 3) Review-sensitive items for this app
- App must be complete and functional at review time.
- Do not download or execute code at runtime. Model files should remain treated as content/data.
- If large model downloads are needed, clearly show size and user-triggered download action.
- Provide clear review notes explaining:
  - app runs fully on-device after model load
  - downloaded files are static model data (`.gguf`)
  - no dynamic executable code is fetched

## 4) App Store Connect metadata required
Create app record, then fill:
- App name, subtitle, category
- Description and keywords
- Privacy Policy URL
- Support URL
- Age rating questionnaire
- App Privacy (data collection labels)
- Export compliance answers (encryption)
- Screenshots for required iPhone display classes (6.9" or 6.5" set)

## 5) Build and upload
In Xcode:
1. Select `Any iOS Device (arm64)`
2. `Product > Archive`
3. In Organizer: `Distribute App > App Store Connect > Upload`
4. Wait for processing in App Store Connect

## 6) Submit for review
In App Store Connect:
- Select processed build
- Complete compliance questions
- Add review notes (template below)
- Submit for review

## 7) App Review notes template (recommended)
Use this in the "Notes" field:

"This app performs local on-device inference using llama.cpp and Metal. The app can download `.gguf` model files as data content selected by the user. It does not download or execute dynamic code. Core functionality: download model, load model, and chat fully on-device (including offline after model load)."

## 8) 2026 timing note
Apple has announced that starting April 28, 2026, uploads require Xcode 26 and the iOS 26 SDK (or later). If you submit before that date, you can still use currently accepted tooling.

## Sources
- App Store Connect overview:
  https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-overview/
- Add an app:
  https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/
- App information (includes privacy policy URL):
  https://developer.apple.com/help/app-store-connect/reference/app-information/
- Submit your app for review:
  https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/
- Upload builds:
  https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/
- App Privacy details:
  https://developer.apple.com/help/app-store-connect/manage-app-privacy/add-or-update-the-app-privacy-details/
- Set age rating:
  https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/
- Export compliance:
  https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/
- Screenshot specifications:
  https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/
- App Review Guidelines:
  https://developer.apple.com/app-store/review/guidelines/
- Membership details:
  https://developer.apple.com/support/compare-memberships/
- Upcoming requirement (Xcode 26 / iOS 26 SDK):
  https://developer.apple.com/news/upcoming-requirements/
