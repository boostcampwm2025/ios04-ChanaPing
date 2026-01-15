export function stripCodeFences(s: string): string {
  return s.replace(/```json/gi, "").replace(/```/g, "").trim();
}

export function extractFirstJSONObject(text: string): string | null {
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end < 0 || start >= end) return null;
  return text.slice(start, end + 1).trim();
}
