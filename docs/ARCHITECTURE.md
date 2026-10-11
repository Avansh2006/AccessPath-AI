# AccessPath AI foundation audit

## Existing implementation

The application is a Flutter mobile client using Provider through a single `AppState` coordinator. UI is organized by feature, but data access is currently routed through `MockPlaceRepository`.

Implemented today:

- OpenStreetMap browsing and a discover feed.
- Text and voice search with geocoding fallback.
- Device location and hand-off to an external navigation app.
- Accessibility preferences and profile-aware score visibility.
- Venue accessibility feature status, confirmation counts, and score breakdowns.
- Structured multi-criterion reviews.
- Place submission with a map picker, duplicate detection, and local persistence.
- Contribution points and recent activity.

## Data and integration audit

- **Persistence:** only locally submitted places are stored with `SharedPreferences`; bundled venues and reviews are hardcoded demo data.
- **Authentication:** no sign-in, sessions, roles, or identity provider.
- **Database/API:** no Supabase, Firebase, or custom application backend.
- **Maps:** OpenStreetMap tiles through `flutter_map`; geocoding uses the device/platform plugin.
- **Scoring:** existing friendly scores are stored on each place and recalculated from review averages after local review changes. They are not yet the required five-category formula.
- **Reviews/photos:** text and structured ratings exist; photo capture, upload, moderation, and remote sharing do not.
- **AI:** no AI-generated summary is implemented.
- **Offline:** local submissions persist on one device, but there is no durable sync queue or conflict handling.

## Problem-statement coverage

| Requirement | Status | Foundation gap |
| --- | --- | --- |
| Public-place map and search | Partial | Demo repository; no production place ingestion or server search |
| Step-free access | Partial | Feature flag exists; needs a normalized rating field |
| Lifts | Partial | Feature flag exists; needs a normalized rating field |
| Accessible washrooms | Partial | Feature flag exists; needs a normalized rating field |
| Seating | Missing | Add schema, review control, and score contribution |
| Wayfinding | Partial | Related features exist; needs a normalized rating field |
| Transparent overall score | Partial | Current score UI exists; required five-category formula must be defined and tested |
| Personalized filtering | Partial | Profile-aware visibility and filters exist; backend queries are absent |
| Community reviews and photos | Partial | Local text reviews exist; accounts, cloud data, and photos are absent |
| Grounded AI summary | Missing | Add a server-side summarizer using stored review IDs as grounding |

## Proposed architecture

Keep the existing feature-first Flutter structure and Provider during the hackathon foundation phase. Introduce interfaces at the data boundary rather than rewriting the UI.

1. Flutter repositories call Supabase for places, category ratings, reviews, media metadata, profiles, and verification votes.
2. PostgreSQL row-level security limits writes to authenticated users and protects profile data.
3. Supabase Storage holds review photographs with size/type validation and moderation status.
4. A server-side Edge Function reads approved reviews, calls Gemini with a constrained prompt, and stores a summary with the exact source review IDs and generation timestamp.
5. A local outbox queues feedback while offline and retries idempotently when connectivity returns.
6. OpenStreetMap remains the map renderer; backend geospatial queries return nearby places and filters.

Privileged Supabase service credentials and Gemini keys must never ship in the Flutter bundle.

## Prioritized roadmap

1. Define the five required rating fields and a documented, deterministic overall-score formula.
2. Add Supabase schema, migrations, row-level security, seed data, and repository interfaces.
3. Add authentication and replace demo identity with real profiles.
4. Replace `MockPlaceRepository` with a Supabase implementation while retaining an explicit demo mode for tests.
5. Add structured filters and remote nearby-place queries.
6. Add photo upload, validation, moderation state, and accessible alt text.
7. Add the server-side grounded review-summary endpoint with citations to source review IDs.
8. Add sync-queue and end-to-end tests before advanced differentiators.

## Exact next engineering task

Create the Supabase database migration for `profiles`, `places`, `place_accessibility_ratings`, `reviews`, `review_photos`, and `verification_votes`, including row-level-security policies and tests for the five-category score input model. Do not connect the UI until the schema and policies have been reviewed.

