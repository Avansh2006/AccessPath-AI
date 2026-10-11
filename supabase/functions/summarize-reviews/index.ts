import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (request) => {
  const headers = { "Content-Type": "application/json" };
  const { placeId } = await request.json();
  if (!placeId) return new Response(JSON.stringify({ status: "error", message: "placeId is required" }), { status: 400, headers });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: request.headers.get("Authorization") ?? "" } } },
  );
  const { data: reviews, error } = await supabase
    .from("reviews")
    .select("comment,created_at,step_free_status,step_free_rating,lifts_status,lifts_rating,accessible_washrooms_status,accessible_washrooms_rating,seating_status,seating_rating,wayfinding_status,wayfinding_rating")
    .eq("place_id", placeId)
    .eq("reported", false)
    .order("created_at", { ascending: false })
    .limit(50);
  if (error) return new Response(JSON.stringify({ status: "error", message: "Stored reviews could not be loaded" }), { status: 500, headers });
  if (!reviews || reviews.length < 3) {
    return new Response(JSON.stringify({ status: "insufficient_feedback", message: "Insufficient community feedback for a reliable summary.", reviewCount: reviews?.length ?? 0 }), { headers });
  }
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) return new Response(JSON.stringify({ status: "unconfigured", message: "AI summaries are not configured.", reviewCount: reviews.length }), { headers });

  const prompt = `Summarize only the supplied accessibility reviews. Mention positive feedback, barriers, disagreements, and freshness. Never infer an unreported facility. Be concise. JSON reviews:\n${JSON.stringify(reviews)}`;
  const gemini = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`, {
    method: "POST", headers, body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }], generationConfig: { temperature: 0.1, maxOutputTokens: 220 } }),
  });
  if (!gemini.ok) return new Response(JSON.stringify({ status: "error", message: "AI summary is temporarily unavailable." }), { status: 502, headers });
  const payload = await gemini.json();
  const summary = payload.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!summary) return new Response(JSON.stringify({ status: "error", message: "AI summary is temporarily unavailable." }), { status: 502, headers });
  return new Response(JSON.stringify({ status: "available", summary, reviewCount: reviews.length, generatedAt: new Date().toISOString() }), { headers });
});
