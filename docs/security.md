# Security model

This document describes the threats KidSpark defends against, the controls
that are in place, and the limitations that are accepted on purpose for an
app of this scope.

## Data the app stores

| Where             | What                                                          |
|-------------------|---------------------------------------------------------------|
| Device prefs      | language code, music/SFX toggles, per-game stars and unlocks |
| Firestore `/users/{uid}` | mirror of the same progress fields, plus `created_at` / `last_updated` timestamps |
| App cache dir     | pre-rendered TTS audio files (WAV/CAF), keyed by SHA-1        |

**No personally identifying information is collected.** There is no email,
password, phone number, name, address, photo, microphone capture, or
analytics SDK. The only identifier ever transmitted is the anonymous Firebase
`uid` chosen by Firebase Auth at first launch.

## Auth model

Authentication is **anonymous only**. On first launch
`ProgressService.init()` calls `signInAnonymously()` and seeds the user's
document. There is no sign-up flow, no account recovery, no shared accounts.
Uninstalling the app loses the anonymous credential and therefore the
linked progress — this is an intentional trade-off to avoid having any form
of identity on file for child users.

## Firestore rules

Rules are in `firestore.rules` at the repo root. The shape is:

```
match /users/{userId} {
  allow read:  if request.auth != null && request.auth.uid == userId;
  allow write: if request.auth != null
               && request.auth.uid == userId
               && request.resource.data.keys().hasOnly([ ...allowlist... ]);
}
match /{document=**} { allow read, write: if false; }
```

This gives three layers of defence:

1. **Auth gate** — every read and write requires a signed-in user.
2. **Ownership gate** — a user can only touch the document whose ID is
   their own `uid`.
3. **Field allow-list** — `hasOnly([...])` rejects writes that include any
   field not on the explicit allow-list. A tampered client cannot inject
   arbitrary keys into the document.

Everything outside `/users/{uid}` is denied by the catch-all rule at the
bottom.

## Threat model

| Threat                                  | Control                                  |
|-----------------------------------------|------------------------------------------|
| Read another user's progress            | Ownership gate in Firestore rules        |
| Write arbitrary keys to a user doc      | `hasOnly` allow-list                     |
| Drop / read collections outside `users` | Default-deny catch-all rule              |
| Capture or exfiltrate PII               | No PII is ever collected                 |
| Insecure HTTP                           | Android Manifest does not enable cleartext traffic; Firebase SDKs are HTTPS-only |
| Code injection / SQLi / XSS             | No raw SQL, no WebView, no `eval`        |
| Path traversal in TTS cache             | File names are SHA-1 hashes of `lang\|text`, written under app-private cache dir |
| Malicious deep link / hijacked task     | `taskAffinity=""` on `MainActivity` and no exported intent filters beyond `LAUNCHER` |
| Signing key disclosure                  | `*.jks`, `*.keystore`, and `key.properties` are gitignored |

## Accepted limitations

These are real but intentionally not fixed in this submission:

- **Star counts are validated client-side only.** A tampered APK could
  write `kidspark_*_stars_*: 3` regardless of in-game performance. There
  is no leaderboard or reward, so this is a low-impact integrity issue.
- **Field type / range validation is light.** The Firestore rules cap
  *which* keys can be written, not their value types. A future iteration
  could tighten the rules to require `int`s within `1..5`.
- **Firebase App Check is not enabled.** The Firebase API key in
  `firebase_options.dart` is meant to be public, but without App Check a
  determined attacker could mint anonymous accounts at scale and create
  empty `users` documents. App Check (Play Integrity) is the recommended
  next step before any production launch.

## Privacy posture

KidSpark is suitable for child users:

- No PII collected, transmitted, or stored.
- No third-party analytics, ads, or in-app purchases.
- No microphone, camera, contacts, or location permission requested.
- Speech is synthesised entirely on-device — phrases are never sent to a
  cloud TTS service.
