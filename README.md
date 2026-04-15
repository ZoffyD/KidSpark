# KidSpark

FYP — Educational game app for special kids.

KidSpark is a Flutter-based landscape tablet app with three mini-games
(Word Builder, Feelings, Logic Puzzle) in English, Bahasa Malaysia and
Simplified Chinese. It is designed for children on the autism spectrum,
with slower TTS, high-contrast visuals and star-based progression.

## Getting started

Requirements:
- Flutter 3.41+ (stable)
- Android SDK / Android Studio
- A Firebase project if you want cloud sync (optional — the app works
  offline via `SharedPreferences` and only syncs to Firestore when
  authenticated)

```bash
flutter pub get
flutter run
```

## Project structure

```
lib/
  main.dart              # app entry, Firebase init, orientation lock
  firebase_options.dart  # Firebase config (see Security notes)
  game_services.dart     # AudioManager + ProgressService (Firestore)
  data/game_content.dart # all level data and translations
  views/
    SplashScreen.dart
    dashboard.dart
    word_builder_game.dart
    emotional_game.dart
    puzzle_game.dart
    settings_screen.dart
  components/reward_animation.dart
  utils/responsive.dart
```

## Data model

The app uses Firebase Anonymous Auth — no email, password, name or any
other personal data is collected. Each device gets an anonymous `uid`
and a single Firestore document at `users/{uid}` containing:

- `created_at`, `last_updated` — server timestamps
- `status` — static flag
- `kidspark_{word|emotional|problem}_unlocked` — highest unlocked level
- `kidspark_{word|emotional|problem}_stars_{1..5}` — best star score per level

No other fields are written by the client, and the Firestore rules in
`firestore.rules` enforce this server-side.

## Security notes

**Firebase API key.** The value in `lib/firebase_options.dart` and
`android/app/google-services.json` is the Firebase *Android* API key.
Per [Google's documentation](https://firebase.google.com/docs/projects/api-keys),
this key identifies your Firebase project to Google's servers — it is
not a secret, and committing it to a public repo is supported. Security
is enforced by:

1. **API key restrictions** in Google Cloud Console — restrict the key
   to the Android app's package name and SHA‑1 fingerprint.
2. **Firestore security rules** — see `firestore.rules`.
3. **Firebase App Check** (recommended for production).

**Deploy the Firestore rules before shipping.** With the Firebase CLI:

```bash
firebase deploy --only firestore:rules
```

The provided rules allow each anonymous user to read/write *only* their
own `users/{uid}` document, and restrict the writable fields to the
whitelist above. All other collections are denied by default.

**Things that are NOT committed (see `.gitignore`):**
- `android/local.properties` (local SDK paths)
- `android/key.properties`, `*.jks`, `*.keystore` (release signing keys)
- `.env` files
- Build artifacts (`/build/`, `.dart_tool/`)

## Before releasing to production

- [ ] Change the Android `applicationId` from `com.example.kidspark` to
      your real package name and re-register with Firebase.
- [ ] Generate a release keystore and replace the debug signing config
      in `android/app/build.gradle.kts`.
- [ ] Restrict the Firebase API key to your release SHA‑1 fingerprint.
- [ ] Deploy `firestore.rules`.
- [ ] Enable Firebase App Check.
