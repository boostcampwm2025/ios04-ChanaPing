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

function getNaverGeocodingCredentials() {
  const apiKeyId = Deno.env.get("NAVER_GEOCODING_API_KEY_ID");
  const apiKey = Deno.env.get("NAVER_GEOCODING_API_KEY");

  if (!apiKeyId || !apiKey) {
    throw new Error("NAVER_GEOCODING_API_KEY_ID or NAVER_GEOCODING_API_KEY is missing");
  }

  return { apiKeyId, apiKey };
}

// ============================================================================
// Type Definitions
// ============================================================================

interface NaverGeocodingResponse {
  status: {
    code: number;
    name: string;
    message: string;
  };
  results: Array<{
    name: string;
    code: {
      id: string;
      type: string;
      mappingId: string;
    };
    region: {
      area0: { name: string };
      area1: { name: string; coords: { center: { x: number; y: number } } };
      area2: { name: string; coords: { center: { x: number; y: number } } };
      area3: { name: string; coords: { center: { x: number; y: number } } };
      area4: { name: string; coords: { center: { x: number; y: number } } };
    };
    land: {
      type: string;
      number1: string;
      number2: string;
      addition0: { type: string; value: string };
      addition1: { type: string; value: string };
      addition2: { type: string; value: string };
      addition3: { type: string; value: string };
      addition4: { type: string; value: string };
      name: string;
      coords: { center: { x: number; y: number } };
    };
  }>;
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
    const { apiKeyId, apiKey } = getNaverGeocodingCredentials();

    // 2. 쿼리 파라미터 파싱 및 검증
    const url = new URL(req.url);
    const longitudeStr = url.searchParams.get("longitude");
    const latitudeStr = url.searchParams.get("latitude");

    if (!longitudeStr || !latitudeStr) {
      return badRequest("longitude and latitude parameters are required");
    }

    const longitude = parseFloat(longitudeStr);
    const latitude = parseFloat(latitudeStr);

    if (isNaN(longitude) || isNaN(latitude)) {
      return badRequest("longitude and latitude must be valid numbers");
    }

    // 3. 네이버 역지오코딩 API 호출 (앱 ReverseGeocodeEndpoint와 동일: maps.apigw.ntruss.com + request=coordsToaddr)
    const coords = `${longitude},${latitude}`;
    const naverUrl = new URL("https://maps.apigw.ntruss.com/map-reversegeocode/v2/gc");
    naverUrl.searchParams.set("request", "coordsToaddr");
    naverUrl.searchParams.set("coords", coords);
    naverUrl.searchParams.set("orders", "roadaddr,addr");
    naverUrl.searchParams.set("output", "json");

    console.log(`[ReverseGeocode] coords="${coords}"`);

    const naverResponse = await fetch(naverUrl.toString(), {
      headers: {
        "X-NCP-APIGW-API-KEY-ID": apiKeyId,
        "X-NCP-APIGW-API-KEY": apiKey,
        "Accept": "application/json",
      },
    });

    if (!naverResponse.ok) {
      const errorText = await naverResponse.text();
      console.error(`[ReverseGeocode] Naver API error: ${naverResponse.status} - ${errorText}`);
      return naverAPIError(
        naverResponse.status,
        `Naver Geocoding API returned error: ${naverResponse.status}`,
        errorText
      );
    }

    // 4. 응답 반환
    const data: NaverGeocodingResponse = await naverResponse.json();
    console.log(`[ReverseGeocode] Success: ${data.results.length} results returned`);

    return jsonResponse(data, 200);

  } catch (error) {
    console.error("[ReverseGeocode] Edge function error:", error);
    const message = error instanceof Error ? error.message : "Unknown error occurred";
    return serverError(message);
  }
});