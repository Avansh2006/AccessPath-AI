# Supabase setup

1. Create a Supabase project and enable anonymous sign-ins.
2. Apply `migrations/202610110001_accesspath_core.sql`.
3. Deploy `summarize-reviews` and set `GEMINI_API_KEY` as an Edge Function secret.
4. Run Flutter with `--dart-define-from-file=.env` using the public URL and anon key from `.env.example`.

Never put the Supabase service-role key or Gemini key in Flutter or `.env`.
