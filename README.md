# AccessPath AI

Community-powered accessibility information for public places, built by **BIT for BYTE**.

AccessPath AI helps people discover places, understand accessibility conditions before travelling, and contribute structured community feedback. The current foundation uses OpenStreetMap and local demo data while the persistent backend and grounded AI-summary service are planned.

## Current capabilities

- Interactive OpenStreetMap with category and accessibility filters.
- Location search, current-location support, voice search, and external directions.
- Profile-aware accessibility and wheelchair-friendly scores with score breakdowns.
- Structured community reviews and accessibility feature confirmations.
- Five-step place submission flow with duplicate checking and a map picker.
- Community contribution points, recent activity, and provisional place status.
- Local persistence for user-added places through `SharedPreferences`.

## Important data status

The bundled venues, reviews, users, scores, and confirmations are demonstration data from `MockPlaceRepository`. They are not live community records. Authentication, cloud sync, photo upload, and AI-generated review summaries are not implemented yet.

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

The app currently needs no secrets. If backend services are added, copy `.env.example` to a local ignored environment file and never commit credentials. Client apps must use only public client keys; Gemini or other privileged AI credentials must remain behind a server-side function.

## Git workflow

- `main`: stable release
- `dev`: integration
- `feat/project-foundation`: foundation and rebrand work

Open a pull request from the feature branch into `dev` after review. Do not merge foundation work directly into `main`.

## Branding and provenance

**AccessPath AI** and **BIT for BYTE** are the current product and team branding. This repository retains source history and required notices. See [NOTICE.md](NOTICE.md) before redistributing the code.

