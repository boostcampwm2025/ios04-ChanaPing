// supabase/functions/messages/index.ts

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getClovaApiKey } from "./config.ts";
import { callClovaModeration } from "./clovaClient.ts";
import type { CreateMessageRequest } from "./requestTypes.ts";
import {
  badRequest,
  methodNotAllowed,
  noContent,
  unprocessableEntity,
  jsonResponse,
} from "./errors.ts";
import { requireUser } from "./auth.ts";
import { insertMessage } from "./messagesRepo.ts";

function isFiniteNumber(v: unknown): v is number {
  return typeof v === "number" && Number.isFinite(v);
}

function validateCreateMessageBody(body: any): CreateMessageRequest | string {
  if (!body || typeof body !== "object") return "Body must be a JSON object";
  if (typeof body.content !== "string" || body.content.trim().length === 0) return "content is required";

  if (body.latitude !== undefined && !isFiniteNumber(body.latitude)) return "coordinate.latitude must be a number";
  if (body.latitude !== undefined && !isFiniteNumber(body.longitude)) return "coordinate.longitude must be a number";

  const place = body.place;
  if (place !== undefined && place !== null) {
    if (typeof place !== "object") return "place must be an object";
      if (place.latitude !== undefined && !isFiniteNumber(place.latitude)) return "place.latitude must be a number";
      if (place.longitude !== undefined && !isFiniteNumber(place.longitude)) return "place.longitude must be a number";
  }

  return body as CreateMessageRequest;
}

function getAdminClient() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl) throw new Error("MISSING_ENV: SUPABASE_URL");
  if (!serviceRoleKey) throw new Error("MISSING_ENV: SUPABASE_SERVICE_ROLE_KEY");

  // service_role key는 Edge Function에서 사용 가능하며 RLS를 우회합니다.
  // 브라우저/클라이언트로 노출되면 안 됩니다.
  return createClient(supabaseUrl, serviceRoleKey);
}

function getTestAuthorId(): string {
  const id = Deno.env.get("TEST_AUTHOR_ID");
  if (!id) throw new Error("MISSING_ENV: TEST_AUTHOR_ID");
  return id;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return methodNotAllowed();

  // 0) 인증 단계 제거: 개발용 고정 author_id 사용
  let authorId: string;
  let adminClient;
  try {
    adminClient = getAdminClient();
    authorId = getTestAuthorId();
  } catch (e) {
    return jsonResponse({ error: (e as Error).message }, 500);
  }

  // TODO: auth 이슈 해결되면 위 0단계 제거 후 아래 두 줄 주석 해제
  // const authed = await requireUser(req);
  // if (authed instanceof Response) return authed;

  // 1) Body 파싱/검증
  let bodyJson: unknown;
  try {
    bodyJson = await req.json();
  } catch {
    return badRequest("Invalid JSON body");
  }

  const validated = validateCreateMessageBody(bodyJson);
  if (typeof validated === "string") return badRequest(validated);

  // 2) CLOVA moderation
  try {
    const apiKey = getClovaApiKey();
    const moderation = await callClovaModeration(validated.content, apiKey);

    // 3) 분기
    if (moderation.decision === "ALLOW" || moderation.decision === "REVIEW") {
      // messagesRepo.insertMessage(client, userId, validated)를 그대로 쓰되
      // userId에 테스트용 authorId를 넣습니다.
      await insertMessage(adminClient, authorId, validated);
      // TODO: auth 이슈 해결되면 윗줄 주석처리, 아랫줄 주석해제
      // await insertMessage(authed.client, authed.userId, validated);
      return noContent(); // 204
    }

    // BLOCK / UNKNOWN → 422
    return unprocessableEntity(
      moderation.decision === "BLOCK" ? "CONTENT_BLOCKED" : "CONTENT_UNKNOWN",
      "Message content is not allowed",
      { decision: moderation.decision, reason: moderation.reason, labels: moderation.labels, score: moderation.score },
    );
  } catch (e) {
    const msg = (e as Error).message ?? "Unknown error";

    if (msg.startsWith("DB_INSERT_FAILED")) {
      return jsonResponse({ error: msg }, 500);
    }

    return jsonResponse({ error: msg }, 502);
  }
});
