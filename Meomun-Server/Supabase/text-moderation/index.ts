// supabase/functions/text-moderation/index.ts
// Deno runtime (Supabase Edge Functions)

import { getClovaApiKey } from "./config.ts";
import { callClovaModeration } from "./clovaClient.ts";

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method Not Allowed" }, 405);
  }

  try {
    const body = await req.json().catch(() => null);
    const text = String(body?.text ?? "").trim();
    if (!text) return jsonResponse({ error: "Empty text field" }, 400);

    const apiKey = getClovaApiKey();
    const result = await callClovaModeration(text, apiKey);
    return jsonResponse(result, 200);
  } catch (e) {
    const msg = (e as Error).message ?? "Unknown error";
    const status =
      msg.startsWith("UNAUTHORIZED") ? 401 :
        msg.startsWith("SERVER_MISCONFIGURED") ? 500 : 502;

    return jsonResponse({ error: msg }, status);
  }
});
