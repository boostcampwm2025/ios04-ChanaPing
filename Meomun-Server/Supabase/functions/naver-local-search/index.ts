import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// ============================================================================
// Helper Functions (에러 응답 및 유틸리티)
// ============================================================================

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    },
  });
}

function badRequest(message: string): Response {
  return jsonResponse({ error: "InvalidParameter", message, statusCode: 400 }, 400);
}

function serverError(message: string): Response {
  return jsonResponse({ error: "InternalServerError", message, statusCode: 500 }, 500);
}

function naverAPIError(statusCode: number, message: string, details?: string): Response {
  return jsonResponse(
    { error: "NaverAPIError", message, statusCode, details },
    statusCode
  );
}

function corsPreflightResponse(): Response {
  return new Response("ok", {
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    },
  });
}

function getNaverCredentials() {
  const clientId = Deno.env.get("NAVER_CLIENT_ID");
  const clientSecret = Deno.env.get("NAVER_CLIENT_SECRET");

  if (!clientId || !clientSecret) {
    throw new Error("NAVER_CLIENT_ID or NAVER_CLIENT_SECRET is missing");
  }

  return { clientId, clientSecret };
}

// ============================================================================
// Type Definitions
// ============================================================================

interface NaverLocalItem {
  title: string;
  category: string;
  address: string;
  roadAddress: string;
  mapx: string;
  mapy: string;
}

interface NaverLocalSearchResponse {
  items: NaverLocalItem[];
}

// ============================================================================
// Main Handler
// ============================================================================

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return corsPreflightResponse();
  }

  try {
    // 1. 환경 변수 로드
    const { clientId, clientSecret } = getNaverCredentials();

    // 2. 쿼리 파라미터 파싱 및 검증
    const url = new URL(req.url);
    const query = url.searchParams.get("query");
    const display = parseInt(url.searchParams.get("display") || "5");
    const start = parseInt(url.searchParams.get("start") || "1");
    const sort = url.searchParams.get("sort") || "random";

    if (!query || query.trim() === "") {
      return badRequest("Query parameter is required");
    }

    // 3. 네이버 API 호출
    const naverUrl = new URL("https://openapi.naver.com/v1/search/local.json");
    naverUrl.searchParams.set("query", query);
    naverUrl.searchParams.set("display", display.toString());
    naverUrl.searchParams.set("start", start.toString());
    naverUrl.searchParams.set("sort", sort);

    console.log(`[LocalSearch] query="${query}", display=${display}, start=${start}`);

    const naverResponse = await fetch(naverUrl.toString(), {
      headers: {
        "X-Naver-Client-Id": clientId,
        "X-Naver-Client-Secret": clientSecret,
      },
    });

    if (!naverResponse.ok) {
      const errorText = await naverResponse.text();
      console.error(`[LocalSearch] Naver API error: ${naverResponse.status} - ${errorText}`);
      return naverAPIError(
        naverResponse.status,
        `Naver API returned error: ${naverResponse.status}`,
        errorText
      );
    }

    // 4. 응답 반환
    const data: NaverLocalSearchResponse = await naverResponse.json();
    console.log(`[LocalSearch] Success: ${data.items.length} items returned`);

    return jsonResponse({ items: data.items }, 200);

  } catch (error) {
    console.error("[LocalSearch] Edge function error:", error);
    const message = error instanceof Error ? error.message : "Unknown error occurred";
    return serverError(message);
  }
});