// supabase/functions/messages/auth.ts

import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";
import { unauthorized } from "./errors.ts";

export interface AuthedContext {
  client: SupabaseClient;
  userId: string;
}

function getEnvOrThrow(key: string): string {
  const v = Deno.env.get(key);
  if (!v) throw new Error(`MISSING_ENV:${key}`);
  return v;
}

export async function requireUser(req: Request): Promise<AuthedContext | Response> {
  // Header는 대소문자 구분이 없지만, 환경별 혼선 방지를 위해 소문자로 읽는 것을 권장
  const authHeader = req.headers.get("authorization");
  if (!authHeader) return unauthorized("Missing Authorization header");

  // "Bearer <token>" robust parsing
  const [scheme, token] = authHeader.split(" ");
  if (!scheme || scheme.toLowerCase() !== "bearer" || !token) {
    return unauthorized("Invalid Authorization header");
  }

  let supabaseUrl: string;
  let supabaseAnonKey: string;

  try {
    supabaseUrl = getEnvOrThrow("SUPABASE_URL");
    supabaseAnonKey = getEnvOrThrow("SUPABASE_ANON_KEY");
  } catch (e) {
    return unauthorized((e as Error).message);
  }

  // RLS를 적용하려면 anonKey + 요청자의 Authorization을 그대로 전달하는 방식이 표준 패턴
  // (Auth context를 세팅하여 policies가 "요청자" 기준으로 적용됨)
  const client = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: {
        authorization: authHeader,
      },
    },
  });

  // getUser는 Auth 서버에 직접 확인하므로 신뢰 가능한 사용자 판별에 적합
  const { data, error } = await client.auth.getUser(token);
  if (error || !data?.user) return unauthorized("Invalid or expired token");

  return { client, userId: data.user.id };
}
