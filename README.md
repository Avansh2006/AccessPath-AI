# AccessPath AI

Community-powered accessibility information for public places, built by **BIT for BYTE**.

AccessPath AI helps people discover places, understand accessibility conditions before travelling, and contribute structured community feedback. It supports local demo mode plus an optional Supabase community backend and grounded Gemini summaries.

## Current capabilities

- Interactive OpenStreetMap with category and accessibility filters.
- Location search, current-location support, voice search, and external directions.
- Profile-aware accessibility and wheelchair-friendly scores with score breakdowns.
- Structured 0–5 reviews for step-free access, lifts, accessible washrooms, seating, and wayfinding, with Unknown and N/A.
- Transparent weighted 0–100 scoring and essential-requirement filtering.
- Five-step place submission flow with duplicate checking and a map picker.
- Community contribution points, recent activity, and provisional place status.
- Local demo persistence plus optional cross-user Supabase storage with RLS.

## Important data status

The bundled venues and reviews are labelled demonstration data. Live cross-user reviews and AI summaries require the setup in `supabase/README.md`; the app never simulates AI output when credentials or feedback are missing.

## Technology

- Flutter and Dart
- Provider state management
- OpenStreetMap through `flutter_map`
- `geolocator`, `geocoding`, and `speech_to_text`
- `shared_preferences` for limited local persistence

The Dart package name remains `access_map` and the existing Android/iOS bundle identifiers remain unchanged during this foundation rebrand to avoid breaking integrations and installed-app upgrade paths.

## Project structure

```text
lib/
├── app/                 # Root app and Provider state
├── core/                # Theme, platform services, scoring visibility
├── features/            # Onboarding, map, places, reviews, profile, contributions
└── shared/              # Models and reusable widgets
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the implementation audit, target architecture, feature gaps, and delivery roadmap.

## Local setup

### Prerequisites

- Flutter 3.24 or later
- Dart version compatible with `^3.9.2`
- Android SDK for Android builds

### Run

```bash
flutter pub get
flutter run
```

### Verify

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Local demo mode needs no secrets. For live community data, apply the migration and Edge Function described in `supabase/README.md`, then pass `SUPABASE_URL` and the public `SUPABASE_ANON_KEY` with `--dart-define`. Store `GEMINI_API_KEY` only as an Edge Function secret; never embed privileged credentials in the client.

## Git workflow

- `main`: stable release
- `dev`: integration
- `feat/project-foundation`: foundation and rebrand work
- `feat/ps-completion`: problem-statement completion work

Open a pull request from the feature branch into `dev` after review. Do not merge foundation work directly into `main`.

## Branding and provenance

**AccessPath AI** and **BIT for BYTE** are the current product and team branding. This repository retains source history and required notices. See [NOTICE.md](NOTICE.md) before redistributing the code.
