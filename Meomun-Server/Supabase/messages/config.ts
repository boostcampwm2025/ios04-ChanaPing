export const ENDPOINT = Deno.env.get("CLOVA_ENDPOINT") ??
  "https://clovastudio.stream.ntruss.com/v3/chat-completions/HCX-005";

export const REQUEST_ID = Deno.env.get("CLOVA_REQUEST_ID") ?? "meomun-moderation";

export const ALLOWED_LABELS = new Set([
  "HARASSMENT",
  "HATE",
  "VIOLENCE",
  "SEXUAL",
  "SELF_HARM",
  "ILLEGAL",
  "PROFANITY",
  "OTHER",
] as const);

export function getClovaApiKey(): string {
  const apiKey = Deno.env.get("CLOVA_API_KEY");
  if (!apiKey) throw new Error("CLOVA_API_KEY is missing");
  return apiKey;
}
