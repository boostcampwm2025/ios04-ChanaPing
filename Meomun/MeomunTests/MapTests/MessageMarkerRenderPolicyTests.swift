//
//  MessageMarkerRenderPolicyTests.swift
//  MeomunTests
//
//  Created by 지연 on 2/4/26.
//

import Testing
@testable import Meomun
import Foundation

struct MessageMarkerRenderPolicyTests {

    @Test("시그니처 동일-렌더 결정-렌더를 스킵한다")
    func decide_skipsWhenSignatureSame() throws {
        let coord = DummyMessageFactory.gangnamStationCoordinate
        let m1 = DummyMessageFactory.noPlaceMessage(createdAt: 1, coordinate: coord)

        let type: MarkerType = .singleBubble(m1)
        let display = [m1]

        let sig = MessageMarkerRenderPolicy.makeSignature(markerType: type, messages: display)

        let decision = MessageMarkerRenderPolicy.decide(
            markerType: type,
            messages: display,
            lastSignature: sig,
            hasFadedIn: true,
            hasAnimationState: false
        )

        #expect(decision == .skipSameSignature)
    }

    @Test("시그니처 변경-single-렌더 결정-렌더가 필요하다")
    func decide_rendersWhenSignatureChanged_single() throws {
        let coord = DummyMessageFactory.gangnamStationCoordinate
        let m1 = DummyMessageFactory.noPlaceMessage(createdAt: 1, coordinate: coord)
        let m2 = DummyMessageFactory.noPlaceMessage(createdAt: 2, coordinate: coord)

        let type1: MarkerType = .singleBubble(m1)
        let type2: MarkerType = .singleBubble(m2)

        let sig1 = MessageMarkerRenderPolicy.makeSignature(markerType: type1, messages: [m1])

        let decision = MessageMarkerRenderPolicy.decide(
            markerType: type2,
            messages: [m2],
            lastSignature: sig1,
            hasFadedIn: true,
            hasAnimationState: false
        )

        // renderNeeded면 signature를 같이 반환해야 하므로 switch로 확인
        switch decision {
        case .renderNeeded:
            #expect(true)
        default:
            #expect(false)
        }
    }

    @Test("rotating/stack + 애니메이션 상태 존재 + hasFadedIn-렌더 결정-초기 렌더 덮어쓰기를 스킵한다")
    func decide_skipsInitialRenderWhenAnimatingAlready() throws {
        let coord = DummyMessageFactory.gangnamStationCoordinate
        let m1 = DummyMessageFactory.noPlaceMessage(createdAt: 1, coordinate: coord)
        let m2 = DummyMessageFactory.noPlaceMessage(createdAt: 2, coordinate: coord)

        let type: MarkerType = .rotatingBubble([m1, m2])
        let display = [m1, m2]

        let decision = MessageMarkerRenderPolicy.decide(
            markerType: type,
            messages: display,
            lastSignature: nil,         // 시그니처가 달라도
            hasFadedIn: true,           // 이미 페이드 완료된 운영 중 마커이고
            hasAnimationState: true     // 애니메이션 상태가 있으면
        )

        #expect(decision == .skipBecauseAnimatingAlready)
    }

    @Test("rotating/stack + hasFadedIn=false-렌더 결정-렌더가 필요하다")
    func decide_rendersWhenNotFadedInYet_evenIfHasAnimationState() throws {
        let coord = DummyMessageFactory.gangnamStationCoordinate
        let m1 = DummyMessageFactory.noPlaceMessage(createdAt: 1, coordinate: coord)
        let m2 = DummyMessageFactory.noPlaceMessage(createdAt: 2, coordinate: coord)

        let type: MarkerType = .rotatingBubble([m1, m2])
        let display = [m1, m2]

        let decision = MessageMarkerRenderPolicy.decide(
            markerType: type,
            messages: display,
            lastSignature: nil,
            hasFadedIn: false,          // 아직 첫 렌더 단계면
            hasAnimationState: true     // 애니 상태가 있어도 렌더해야 함
        )

        switch decision {
        case .renderNeeded:
            #expect(true)
        default:
            #expect(false)
        }
    }
}
