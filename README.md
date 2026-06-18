# LabourLink

A Flutter mobile app that connects **Seekers** (skilled workers) with **Recruiters** (employers). Built with Firebase for auth and real-time data, Cloudinary for media, and Provider for state management.

---

## Features

### Core workflow
- Email/password authentication with role selection (Seeker / Recruiter)
- Worker discovery by profession, hire requests, and accept/reject flow
- OTP-verified job sessions with real-time status updates
- UPI payment flow after job completion
- Government ID verification with admin review status

### Real-time & location
- Live worker location tracking during active jobs
- Google Maps route display and ETA estimation
- In-app chat between recruiter and seeker

### Modules
- **Booking history** — completed, pending, and cancelled jobs
- **Scheduled bookings** — future date/time with accept/reject and reminders
- **Skill certificates** — upload licenses (image/PDF) via Cloudinary
- **Earnings dashboard** — income stats for seekers from paid jobs
- **Fraud prevention** — cooldowns, OTP attempt limits, abuse logging

### Other
- Push notifications (FCM + local notifications)
- Ratings and reviews after completed jobs
- Profile photos and ID proofs hosted on Cloudinary (URLs stored in Firebase)

---

## Tech stack

| Layer | Technology |
|--------|------------|
| Framework | Flutter 3.x (Dart ^3.8) |
| State | [Provider](https://pub.dev/packages/provider) |
| Auth & DB | Firebase Auth, Firebase Realtime Database |
| Media | Cloudinary (unsigned uploads) |
| Maps | Google Maps Flutter, Directions API |
| Notifications | Firebase Cloud Messaging, flutter_local_notifications |
| Payments | UPI intent via `url_launcher` |

---

## Project structure

```
lib/
├── core/           # Theme, constants, shared widgets, validators
├── data/
│   ├── models/     # DTOs (AppUser, JobSession, etc.)
│   ├── repositories/
│   └── services/   # Cloudinary, FCM, payments, fraud, location
├── domain/         # Repository interfaces
└── presentation/
    ├── providers/  # ChangeNotifier state
    └── screens/    # auth/, seeker/, recruiter/, common/
```

---

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable, 3.27+)
- Android Studio / Xcode (for device emulators)
- A [Firebase](https://console.firebase.google.com/) project
- A [Cloudinary](https://cloudinary.com/) account
- Google Maps / Directions API key (for maps & ETA)

---

## Setup

### 1. Clone and install dependencies

```bash
git clone https://github.com/YOUR_USERNAME/LabourLink.git
cd LabourLink
flutter pub get
```

### 2. Firebase

1. Create a Firebase project and enable **Authentication** (Email/Password) and **Realtime Database**.
2. Register Android and/or iOS apps in the Firebase console.
3. Download config files and place them in the project:
   - **Android:** `android/app/google-services.json`
   - **iOS:** `ios/Runner/GoogleService-Info.plist`
4. Use Realtime Database rules appropriate for your environment (start in test mode for development, then tighten for production).

**Realtime Database roots used by the app:**

| Path | Purpose |
|------|---------|
| `Users/{uid}` | User profiles, verification, payment setup |
| `Seeker/{profession}/{uid}` | Seeker index for discovery |
| `HiringRequests/{recruiterId}/{workerId}` | Hire workflow |
| `JobSessions/{jobId}` | OTP sessions, payment status |
| `ScheduledBookings/{bookingId}` | Future bookings |
| `Chats/`, `Ratings/`, `Earnings/`, `FraudLogs/` | Chat, reviews, analytics, abuse logs |

### 3. Cloudinary (profile photos, ID proofs, certificates)

1. In Cloudinary Dashboard → **Settings → Upload**, create an **unsigned** upload preset named `labourlink_upload`.
2. Allow image and raw (PDF) formats as needed.
3. Update cloud name / preset in `lib/core/constants/cloudinary_constants.dart` if you use your own account:

```dart
static const String cloudName = 'your_cloud_name';
static const String uploadPreset = 'labourlink_upload';
```

> **Never** commit your Cloudinary API secret to this repo. The app uses unsigned uploads only.

### 4. API keys

Edit `lib/core/constants/app_constants.dart`:

```dart
static const String fcmServerKey = 'YOUR_FCM_SERVER_KEY_HERE';
static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
```

- **FCM:** Firebase Console → Project Settings → Cloud Messaging → Server key (legacy). For production, prefer Cloud Functions instead of client-side sending.
- **Maps:** [Google Cloud Console](https://console.cloud.google.com/) → enable Maps SDK for Android/iOS and Directions API.

### 5. Android build notes

`android/app/build.gradle.kts` enables **core library desugaring** (required by `flutter_local_notifications`). No extra steps needed if you clone this repo as-is.

---

## Run the app

```bash
# List devices
flutter devices

# Debug run
flutter run

# Release APK (Android)
flutter build apk --release
```

---

## User roles

| Role | Description |
|------|-------------|
| **Seeker** | Worker — accepts hires, confirms OTP, completes jobs, tracks earnings |
| **Recruiter** | Employer — finds workers, starts sessions, pays via UPI, schedules bookings |

Both roles share verification, profile photo upload, chat, and booking history.

---

## Environment & secrets

Do **not** commit:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart` (if generated)
- API keys, keystore files, or `.env` files

These paths are listed in `.gitignore`. Copy from your Firebase console when setting up locally.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `checkDebugAarMetadata` / desugaring error | Ensure `isCoreLibraryDesugaringEnabled = true` in `android/app/build.gradle.kts` |
| Profile / ID upload fails | Verify Cloudinary unsigned preset `labourlink_upload` exists and is enabled |
| Maps blank | Set `googleMapsApiKey` and enable Maps SDK in Google Cloud |
| Push notifications not sent | Set `fcmServerKey` or move notification sending to a backend |
| Gradle / Firebase plugin errors | Run `flutter clean && flutter pub get` |

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

---

## License

This project is provided as-is for educational and portfolio use. Add your preferred license (e.g. MIT) before public distribution if required.

---

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Firebase](https://firebase.google.com/)
- [Cloudinary](https://cloudinary.com/)
