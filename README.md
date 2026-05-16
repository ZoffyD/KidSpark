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

The first launch pre-renders every spoken phrase to a local audio cache —
expect a one-time progress bar (~30 s) on the splash screen.

## Project structure

```
lib/
  main.dart                  # app entry, Firebase init, orientation lock

  firebase/
    firebase_options.dart    # generated Firebase config — don't edit

  core/                      # shared constants, helpers, static data
    app_constants.dart       # PrefsKeys, GameType, AppColors, AppRadii
    app_utils.dart           # Responsive scaling, tr() language picker
    game_content.dart        # all level data + translations

  services/
    game_services.dart       # AudioManager + ProgressService + TtsCache

  views/                     # everything the user sees on screen
    splash_screen.dart       # splash + speech-cache warm-up
    dashboard.dart           # main hub (sidebar + level map)
    word_builder_game.dart   # spell-the-word mini-game
    emotional_game.dart      # pick-the-feeling mini-game
    puzzle_game.dart         # drag-the-answer mini-game
    settings_screen.dart     # music / SFX toggles + credits
    reward_animation.dart    # end-of-level reward dialog
```

Four folders, each with a one-word job: **firebase/** for generated config,
**core/** for shared knobs and helpers, **services/** for non-UI logic, and
**views/** for screens and dialogs. `main.dart` stays at the root because
it's the entry point.

### Where do I look for...?

| If you want to change...                           | Open this file                       |
|----------------------------------------------------|--------------------------------------|
| App startup / Firebase boot order                  | `lib/main.dart`                      |
| Splash screen / first-launch speech-cache progress | `lib/views/splash_screen.dart`       |
| Sidebar, level map, language toggle                | `lib/views/dashboard.dart`           |
| Word Builder, Feelings, or Logic gameplay          | `lib/views/word_builder_game.dart` and siblings |
| End-of-level "well done" dialog                    | `lib/views/reward_animation.dart`    |
| Music / SFX / TTS / progress / speech cache        | `lib/services/game_services.dart`    |
| Level prompts, options, translations               | `lib/core/game_content.dart`         |
| Prefs keys / GameType / colours / radii            | `lib/core/app_constants.dart`        |
| Phone-vs-tablet scaling, `tr(en, ms, zh)` helper   | `lib/core/app_utils.dart`            |
| Generated Firebase config                          | `lib/firebase/firebase_options.dart` |
| Firestore security rules                           | `firestore.rules` (repo root)        |

### Reading order for a new contributor

1. `lib/main.dart` — see how the app boots.
2. `lib/views/splash_screen.dart` → `lib/views/dashboard.dart` — the entry UI.
3. Pick one game view (e.g. `word_builder_game.dart`) and read it end-to-end.
4. Skim the three service files in `lib/services/`.
5. Glance at `lib/data/game_content.dart` to see the level shape.

See [`docs/architecture.md`](docs/architecture.md) for the layered diagram and
the rationale behind the split, and [`docs/security.md`](docs/security.md) for
the threat model.

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
   to the Android app's package name and SHA-1 fingerprint.
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

## Building a release APK

```bash
flutter build apk --release
```

Output is written to `build/app/outputs/flutter-apk/`.

## Before releasing to production

- [ ] Change the Android `applicationId` from `com.example.kidspark` to
      your real package name and re-register with Firebase.
- [ ] Generate a release keystore and replace the debug signing config
      in `android/app/build.gradle.kts`.
- [ ] Restrict the Firebase API key to your release SHA-1 fingerprint.
- [ ] Deploy `firestore.rules`.
- [ ] Enable Firebase App Check.

## Credits

- Background music: *Momo Island* by Piki — `freetouse.com/music`
- Imagery: created with Canva under the Canva Content License Agreement.
