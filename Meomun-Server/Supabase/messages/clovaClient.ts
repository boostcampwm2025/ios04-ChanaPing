import type { ModerationResult } from "./types.ts";
import { ENDPOINT, REQUEST_ID } from "./config.ts";
import { buildSystemPrompt } from "./prompt.ts";
import { extractContentFromJsonResponse } from "./extractContent.ts";
import { stripCodeFences, extractFirstJSONObject } from "./jsonExtract.ts";
import { validateModerationResult } from "./validate.ts";

export async function callClovaModeration(text: string, apiKey: string): Promise<ModerationResult> {
  const systemPrompt = buildSystemPrompt();

  const body = {
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: `텍스트: """${text}"""` },
    ],
    topP: 0.5,
    topK: 0,
    maxTokens: 256,
    temperature: 0.0,
    repetitionPenalty: 1.1,
    stop: [],
    seed: 0,
    includeAiFilters: true,
  };

  const res = await fetch(ENDPOINT, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-NCP-CLOVASTUDIO-REQUEST-ID": REQUEST_ID,
      "Authorization": `Bearer ${apiKey}`,
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const raw = await res.text().catch(() => "");
    throw new Error(`요청 실패(${res.status}):\n${raw.slice(0, 4000)}`);
  }

  const payload = await res.json().catch(async () => {
    const raw = await res.text().catch(() => "");
    throw new Error(`응답 JSON 파싱 실패. raw:\n${raw.slice(0, 2000)}`);
  });

  const content = extractContentFromJsonResponse(payload);
  if (!content) throw new Error(`응답에서 content를 찾지 못했습니다.`);

  const cleaned = stripCodeFences(content.trim());
  const jsonOnly = extractFirstJSONObject(cleaned);
  if (!jsonOnly) throw new Error(`모델 응답에서 JSON 객체를 찾지 못했습니다.\n원문:\n${cleaned}`);

  const obj = JSON.parse(jsonOnly);
  return validateModerationResult(obj);
}
