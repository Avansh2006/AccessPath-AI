# Live Accessibility Explorer

The Map tab discovers venues near the user's current location (falls back to
the default area with a banner when location is denied/off/unavailable).

- **Filters:** Hospitals, Restaurants, Malls, Parks, Transport, Other venues;
  radius 1 / 2 / 5 km around the user's location.
- **Markers:** coloured by personal suitability, computed only from community
  ratings of the five criteria relevant to the user's profile needs and
  chosen essentials (`SuitabilityEvaluator` in
  `lib/features/map/domain/live_map_explorer.dart`).
  Green = good fit (>= 70/100), amber = partial, red = poor (< 50), grey =
  no ratings. A relevant criterion rated below 60 caps a good fit at
  partial. Hollow markers = low confidence (1 review or < 50% of relevant
  criteria rated); a badge marks high confidence (>= 3 reviews, all
  relevant criteria rated). Unknown is never treated as accessible.
- **Venue card:** personal fit, overall score, all five categories, latest
  community review and community-uploaded photos (only `http(s)` URLs are
  loaded; no third-party photo sources).

## Realtime integration requirement

`SupabasePlaceRepository` subscribes to Postgres changes on `public.places`
and `public.reviews`. Supabase only emits these events when the tables are in
the `supabase_realtime` publication. The existing migration does not do this,
so a backend owner needs to run (or add in a new migration):

```sql
alter publication supabase_realtime add table public.places, public.reviews;
```

Without it the map still works; the "Live updates" chip reflects the channel
connection only, and data refreshes on load / location change.
