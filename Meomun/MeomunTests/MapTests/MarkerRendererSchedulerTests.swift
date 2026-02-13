//
//  MarkerRenderSchedulerTests.swift
//  MeomunTests
//
//  Created by 지연 on 2/4/26.
//

import Testing
@testable import Meomun
import UIKit
import Foundation

// 테스트용: sleep 없는 페이드
struct ImmediateFadeAnimator: MarkerFadeAnimating {
    func applyFadeIn(_ image: UIImage, to marker: MarkerProtocol, key: MarkerGroupKey) async {
        marker.setIcon(image)
        marker.alpha = 1.0
    }
}

// 테스트용: 렌더 완료 타이밍 제어
final class ControllableBubbleRenderer: BubbleImageRendering {
    private(set) var singleCount = 0

    // 여러 Task가 동시에 들어올 수 있으므로 큐로 관리
    private var continuations: [CheckedContinuation<UIImage, Never>] = []

    var pendingSingleContinuationsCount: Int { continuations.count }

    func setColorScheme(_ traitCollection: UITraitCollection) {}

    func renderSingleBubble(message: Message, scale: CGFloat? = nil) async -> UIImage {
        singleCount += 1

        return await withCheckedContinuation { cont in
            continuations.append(cont)
        }
    }

    func renderRotatingBubble(
        current: Message,
        next: Message,
        progress: Double,
        scale: CGFloat? = nil
    ) async -> UIImage {
        UIImage()
    }

    // 테스트에서 다음 렌더를 완료시키기 위한 API
    func resumeNextSingle(returning image: UIImage = UIImage()) {
        guard !continuations.isEmpty else { return }
        let cont = continuations.removeFirst()
        cont.resume(returning: image)
    }
}

struct MarkerRenderSchedulerTests {

    private func waitUntil(
        _ condition: @escaping @MainActor () -> Bool,
        maxYields: Int = 300
    ) async {
        for _ in 0..<maxYields {
            let ok = await MainActor.run { condition() }
            if ok { return }
            await Task.yield()
        }
        Issue.record("조건을 만족하지 못했습니다(타이밍 문제 가능).")
    }

    @Test("연속 스케줄-Task 누적 방지-마지막 호출만 아이콘이 적용된다")
    func scheduleInitialRender_cancelsPreviousTask_onlyLatestApplies() async {
        let renderer = await MainActor.run { ControllableBubbleRenderer() }
        let scheduler = await MainActor.run {
            MarkerRenderScheduler(renderer: renderer, fadeAnimator: ImmediateFadeAnimator())
        }

        let coord = DummyMessageFactory.gangnamStationCoordinate
        let m1 = DummyMessageFactory.noPlaceMessage(createdAt: 1, coordinate: coord)

        let key = MarkerGroupKey(coordinate: coord, isPlace: false)
        let marker = SpyMarker()
        let currentMarker: MarkerProtocol? = marker

        await MainActor.run {
            scheduler.scheduleInitialRender(
                for: key,
                marker: marker,
                markerType: .singleBubble(m1),
                animationStateProvider: { nil },
                currentMarkerForKey: { currentMarker }
            )
        }

        await MainActor.run {
            scheduler.scheduleInitialRender(
                for: key,
                marker: marker,
                markerType: .singleBubble(m1),
                animationStateProvider: { nil },
                currentMarkerForKey: { currentMarker }
            )
        }

        // continuation이 최소 1개 이상 생길 때까지 대기
        await waitUntil({ renderer.pendingSingleContinuationsCount >= 1 })

        // pending 전부 풀어준다 (취소 Task 쪽도 포함)
        await MainActor.run {
            while renderer.pendingSingleContinuationsCount > 0 {
                renderer.resumeNextSingle()
            }
        }

        // 적용될 때까지 대기
        await waitUntil({ marker.iconSetCount == 1 && marker.alpha == 1.0 })

        #expect(marker.iconSetCount == 1)
        #expect(marker.alpha == 1.0)
    }

    @Test("마커 교체-적용 검증-이전 마커에는 아이콘이 적용되지 않는다")
    func scheduleInitialRender_markerReplaced_doesNotApplyToOldMarker() async {
        let renderer = await ControllableBubbleRenderer()
        let scheduler = await MainActor.run {
            MarkerRenderScheduler(renderer: renderer, fadeAnimator: ImmediateFadeAnimator())
        }

        let coord = DummyMessageFactory.gangnamStationCoordinate
        let m1 = DummyMessageFactory.noPlaceMessage(createdAt: 1, coordinate: coord)

        let key = MarkerGroupKey(coordinate: coord, isPlace: false)

        let oldMarker = SpyMarker()
        let newMarker = SpyMarker()

        var currentMarker: MarkerProtocol? = oldMarker

        // oldMarker로 스케줄
        await MainActor.run {
            scheduler.scheduleInitialRender(
                for: key,
                marker: oldMarker,
                markerType: .singleBubble(m1),
                animationStateProvider: { nil },
                currentMarkerForKey: { currentMarker }
            )
        }

        // renderer 진입 대기
        await waitUntil({ renderer.pendingSingleContinuationsCount == 1 })

        // render 완료 전에 marker 교체 발생(Manager에서 markers[key]가 바뀐 상황)
        currentMarker = newMarker

        // render 완료
        await MainActor.run {
            renderer.resumeNextSingle()
        }
        await Task.yield()

        #expect(oldMarker.iconSetCount == 0)
        #expect(newMarker.iconSetCount == 0) // 이 테스트는 old에 적용 금지만 확인 (새로 스케줄 안 했으므로 0이 정상)
    }
}
