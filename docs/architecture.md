# Architecture

KidSpark follows a small, deliberately flat four-layer architecture. The goal
was to keep the code readable for a final-year project rather than to
demonstrate every Flutter pattern in existence.

## Layered view

```
┌────────────────────────────────────────────────────────────┐
│  Views (lib/views/)                                        │
│   splash_screen, dashboard,                                │
│   word_builder_game, emotional_game, puzzle_game,          │
│   settings_screen                                          │
├────────────────────────────────────────────────────────────┤
│  Components (lib/components/)                              │
│   reward_animation                                         │
├────────────────────────────────────────────────────────────┤
│  Services (lib/services/) — singletons                     │
│   AudioManager     music, SFX, TTS, lifecycle hooks        │
│   ProgressService  unlocks + stars (local + Firestore)     │
│   TtsCache         pre-renders every phrase to disk        │
├────────────────────────────────────────────────────────────┤
│  Data + Platform                                           │
│   data/game_content.dart  (level + translation tables)     │
│   constants/  theme/  utils/  firebase_options.dart        │
└────────────────────────────────────────────────────────────┘
```

The dependency direction is one-way: **views → services → data**. Services
never import views, and data never imports services. This makes individual
layers easy to reason about and avoids circular imports.

## Why a barrel file?

`lib/game_services.dart` is now a thin barrel that re-exports the three
service files. Earlier in development everything lived in one 685-line file;
splitting it gave each service its own home while keeping the existing
`import '../game_services.dart';` lines in the views working unchanged.

## Why singletons for services?

The three services (`AudioManager`, `ProgressService`, `TtsCache`) all wrap
process-global resources — the OS audio focus, the user's Firebase auth
session, and an on-disk cache directory. Allowing more than one instance of
any of them would either crash or quietly corrupt state, so the singleton
pattern is a fit here. For an app of this size it is a deliberate simpler
choice than wiring up a DI container.

## Offline-first progress

Every progress write goes through `ProgressService` and lands in
`SharedPreferences` first. Firestore mirroring is best-effort:

```
saveStars(...)
   └─► prefs.setInt(...)            // always succeeds
        └─► await db.set(..., merge: true)   // may fail offline; that's OK
```

Firestore offline persistence is enabled in `main.dart`, so writes that fail
(no network) are queued by the SDK and replayed when connectivity returns.
The user never blocks on the network.

## Speech cache

The first launch pre-renders every phrase the app might ever speak — UI
labels, level greetings, scenario prompts, every option label, every Word
Builder tile — to disk under the application cache directory. Subsequent
calls to `AudioManager.speak()` look the cache up by `lang|text` and stream
the WAV/CAF instead of waking the TTS engine, which makes language switching
feel instant.

The cache is versioned (`tts_cache_v1`); bumping the version invalidates
old files automatically.

## State management

KidSpark is small enough that bare `setState` + a single
`ValueNotifier<String>` for the current language is enough. There is no
Riverpod / BLoC / Provider layer, and adding one was not worth the
ceremony for three screens.

## Testing strategy

Manual testing on Android only. Unit tests are not included in this
submission — they were considered out of scope for an interactive UI app
of this size.
