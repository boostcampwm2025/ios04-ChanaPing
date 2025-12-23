//
//  TextModerationViewModel.swift
//  Meomun
//
//  Created by 송지연 on 12/22/25.
//

import SwiftUI
import Combine

// MARK: - Model

struct ModerationResult: Codable {
    enum Decision: String, Codable {
        case ALLOW, REVIEW, BLOCK
        case UNKNOWN

        init(from decoder: Decoder) throws {
            let value = try decoder.singleValueContainer().decode(String.self)
            self = Decision(rawValue: value) ?? .UNKNOWN
        }
    }
    var decision: Decision
    var labels: [String]
    var score: Double
    var reason: String
}

enum ModerationState {
    case idle
    case loading
    case success(ModerationResult)
    case failure(String)
}

// MARK: - ViewModel

@MainActor
final class TextModerationViewModel: ObservableObject {

    @Published var inputText: String = ""
    @Published private(set) var state: ModerationState = .idle

    // curl의 Bearer <api-key> 값(토큰 값만)
    private let apiKey: String = AppConfig.naverAPIKey

    private let requestId: String = "meomun-moderation-demo"
    private let endpoint = URL(string: "https://clovastudio.stream.ntruss.com/v3/chat-completions/HCX-005")!

    func runModeration() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            state = .failure("텍스트를 입력해줘")
            return
        }

        state = .loading
        do {
            let result = try await callClovaModeration(text: text)
            state = .success(result)
        } catch {
            state = .failure(error.localizedDescription)
        }
    }

    // MARK: - CLOVA call (SSE)

    private func callClovaModeration(
        text: String
    ) async throws -> ModerationResult {
        let systemPrompt =
"""
너는 한국어 사용자 생성 텍스트(UGC) 안전성/매너 검열기다.
서비스 정책은 "타인에 대한 비하/모욕/조롱/혐오"를 강하게 제한한다.

판정 규칙(반드시 준수):
- BLOCK: 명확한 욕설/모욕/비하/조롱, 외모/신체/장애/인종/성별 등 대상에 대한 공격, 혐오 표현, 성적 모욕, 폭력/자해/불법 조장
- REVIEW: 모욕/비하 의도가 강하게 의심되거나, 특정 대상을 겨냥하지 않았더라도 공격적 표현(예: "개같다", "개웃기게 생김", "병신같다" 등), 조롱/비아냥, 경멸적 표현
- ALLOW: 공격성/비하/모욕이 없고 중립적인 표현

특수 규칙:
- 비속어 접두(개-, 존나, ㅈㄴ 등) + 사람/외모/행동 평가가 결합되면 최소 REVIEW
- "웃기게 생김"처럼 외모/인상 평가로 타인을 낮추는 표현은 최소 REVIEW (정책상 공격성으로 취급)
- 대상이 불특정이라도 공격적 표현이면 REVIEW 이상

출력은 반드시 하나의 JSON 객체만. JSON 외 텍스트 금지.
decision은 ALLOW|REVIEW|BLOCK 중 하나.
labels는 아래 중에서만 선택:
["HARASSMENT","HATE","VIOLENCE","SEXUAL","SELF_HARM","ILLEGAL","PROFANITY","OTHER"]

출력 형식:
{
  "decision": "ALLOW|REVIEW|BLOCK",
  "labels": [],
  "score": 0.0,
  "reason": "한국어로 짧은 근거"
}
"""

        // curl 파라미터 + user 메시지까지 포함
        let body: [String: Any] = [
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "텍스트: \"\"\"\(text)\"\"\""]
            ],
            "topP": 0.5,
            "topK": 0,
            "maxTokens": 256,
            "temperature": 0.0,
            "repetitionPenalty": 1.1,
            "stop": [],
            "seed": 0,
            "includeAiFilters": true
        ]

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        req.setValue(requestId, forHTTPHeaderField: "X-NCP-CLOVASTUDIO-REQUEST-ID")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 20
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (bytes, response) = try await URLSession.shared.bytes(for: req)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200..<300).contains(http.statusCode) else {
            var raw = ""
            for try await line in bytes.lines.prefix(50) { raw += line + "\n" }
            throw NSError(domain: "CLOVA", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "요청 실패(\(http.statusCode)):\n\(raw)"])
        }

        var accumulated = ""
        var finalContent: String? = nil

        for try await line in bytes.lines {
            guard line.hasPrefix("data:") else { continue }
            let payload = line.dropFirst("data:".count).trimmingCharacters(in: .whitespacesAndNewlines)

            if payload == "[DONE]" || payload.contains("\"data\":\"[DONE]\"") {
                break
            }

            guard let (chunk, isFinal) = extractContentAndFinish(fromSSEPayload: Data(payload.utf8)) else {
                continue
            }

            if isFinal {
                // 최종본이 오면 그걸로 확정
                finalContent = chunk
                break
            } else {
                accumulated += chunk
            }
        }

        let contentToDecode = (finalContent ?? accumulated).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !contentToDecode.isEmpty else {
            throw NSError(domain: "CLOVA", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "스트림에서 content를 못 받았어"])
        }

        return try decodeModerationResult(from: contentToDecode)
    }
    /// payload에서 (content, isFinal)을 뽑아냄
    private func extractContentAndFinish(fromSSEPayload data: Data) -> (String, Bool)? {
        guard
            let obj = try? JSONSerialization.jsonObject(with: data),
            let dict = obj as? [String: Any]
        else { return nil }

        if let done = dict["data"] as? String, done == "[DONE]" {
            return nil
        }

        if let message = dict["message"] as? [String: Any],
           let content = message["content"] as? String {

            let finishReason = dict["finishReason"] as? String
            let isFinal = (finishReason == "stop" || finishReason == "length" || finishReason == "end")
            return (content, isFinal)
        }

        return nil
    }
    /// SSE payload JSON에서 "content 조각"을 뽑아낸다.
    /// CLOVA/LLM 스트리밍은 보통 choices[0].delta.content 형태지만,
    /// 스펙이 다를 수 있어서 여러 경로를 다 시도함.
    private func extractContentChunk(fromSSEPayload data: Data) -> String? {
        guard
            let obj = try? JSONSerialization.jsonObject(with: data, options: []),
            let dict = obj as? [String: Any]
        else { return nil }

        if let done = dict["data"] as? String, done == "[DONE]" {
            return nil
        }

        if let message = dict["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }

        // 다른 스키마 대비용
        if let choices = dict["choices"] as? [[String: Any]],
           let delta = choices.first?["delta"] as? [String: Any],
           let content = delta["content"] as? String {
            return content
        }

        if let choices = dict["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }

        if let result = dict["result"] as? [String: Any],
           let message = result["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }

        return nil
    }

    private func decodeModerationResult(from content: String) throws -> ModerationResult {
        // 1) 코드블록 제거 + 트림
        let cleaned = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // 2) content 안에 섞여있는 텍스트 제거: JSON 객체만 추출
        guard let jsonOnly = extractFirstJSONObject(from: cleaned) else {
            throw NSError(
                domain: "CLOVA",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "모델 응답에서 JSON 객체를 못 찾았어.\n원문:\n\(cleaned)"]
            )
        }

        // 3) 디코딩
        do {
            return try JSONDecoder().decode(ModerationResult.self, from: Data(jsonOnly.utf8))
        } catch {
            throw NSError(
                domain: "CLOVA",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "JSON 디코딩 실패: \(error.localizedDescription)\nJSON:\n\(jsonOnly)"]
            )
        }
    }

    /// 문자열 안에서 첫 번째 JSON 오브젝트( {...} )를 추출
    private func extractFirstJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else { return nil }
        guard start < end else { return nil }
        return String(text[start...end]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
