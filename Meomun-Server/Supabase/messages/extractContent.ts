export function extractContentFromJsonResponse(payload: any): string | null {
  if (payload?.message?.content && typeof payload.message.content === "string") {
    return payload.message.content;
  }
  if (Array.isArray(payload?.choices) && payload.choices.length > 0) {
    const first = payload.choices[0];
    if (first?.message?.content && typeof first.message.content === "string") {
      return first.message.content;
    }
  }
  if (payload?.result?.message?.content && typeof payload.result.message.content === "string") {
    return payload.result.message.content;
  }
  if (typeof payload?.content === "string") return payload.content;
  return null;
}
