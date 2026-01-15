// supabase/functions/messages/errors.ts

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

export function noContent(): Response {
  return new Response(null, { status: 204 });
}

export function badRequest(message: string): Response {
  return jsonResponse({ error: message }, 400);
}

export function unauthorized(message = "Unauthorized"): Response {
  return jsonResponse({ error: message }, 401);
}

export function unprocessableEntity(code: string, message: string, extra?: Record<string, unknown>): Response {
  return jsonResponse({ error: message, code, ...extra }, 422);
}

export function methodNotAllowed(): Response {
  return jsonResponse({ error: "Method Not Allowed" }, 405);
}
