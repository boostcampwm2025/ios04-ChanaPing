//
//  MarkerRenderScheduler.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

import UIKit

@MainActor
final class MarkerRenderScheduler {

    private let renderer: BubbleImageRendering
    private let fadeAnimator: MarkerFadeAnimating

    /// 마커별 렌더링 Task (누적 방지, 최신만 반영)
    private var renderTasks: [MarkerGroupKey: Task<Void, Never>] = [:]

    /// 페이드 관리용 Task
    private var fadeTasks: [MarkerGroupKey: Task<Void, Never>] = [:]

    /// 마커 페이드인 여부 상태 플래그
    private var hasFadedIn: Set<MarkerGroupKey> = []

    init(
        renderer: BubbleImageRendering,
        fadeAnimator: MarkerFadeAnimating = MarkerFadeAnimator()
    ) {
        self.renderer = renderer
        self.fadeAnimator = fadeAnimator
    }

    func hasFadedIn(_ key: MarkerGroupKey) -> Bool {
        hasFadedIn.contains(key)
    }

    func resetFadedInState(for key: MarkerGroupKey) {
        hasFadedIn.remove(key)
    }

    func cancelAllTasks(for key: MarkerGroupKey) {
        renderTasks[key]?.cancel()
        renderTasks.removeValue(forKey: key)

        fadeTasks[key]?.cancel()
        fadeTasks.removeValue(forKey: key)
    }

    func scheduleInitialRender(
        for key: MarkerGroupKey,
        marker: MarkerProtocol,
        markerType: MarkerType,
        animationStateProvider: @escaping () -> BubbleAnimationState?,
        currentMarkerForKey: @escaping () -> MarkerProtocol?
    ) {
        // 기존 렌더 작업 취소 (최신만 반영)
        renderTasks[key]?.cancel()

        renderTasks[key] = Task { @MainActor in
            let image: UIImage

            switch markerType {
            case .singleBubble(let message):
                image = await renderer.renderSingleBubble(message: message)

            case .rotatingBubble(let messages), .stackBubble(let messages):
                guard messages.count >= 1 else { return }

                if let state = animationStateProvider(), state.messages.count >= 1 {
                    let snap = state.messages
                    let current = state.currentMessage ?? snap[0]
                    let next = state.nextMessage ?? snap[min(1, snap.count - 1)]

                    image = await renderer.renderRotatingBubble(
                        current: current,
                        next: next,
                        progress: state.isAnimating ? state.animationProgress : 0
                    )
                } else {
                    // state가 아직 없거나 준비 전이면 messages로 fallback
                    let current = messages[0]
                    let next = messages[min(1, messages.count - 1)]
                    image = await renderer.renderRotatingBubble(
                        current: current,
                        next: next,
                        progress: 0
                    )
                }
            }

            // 취소되었으면 적용 X
            if Task.isCancelled { return }

            // 아직 이 key의 현재 마커가 이 marker인지 확인
            guard let current = currentMarkerForKey(), current === marker else { return }

            if hasFadedIn.contains(key) {
                marker.setIcon(image)
                marker.alpha = 1.0
            } else {
                hasFadedIn.insert(key)

                fadeTasks[key]?.cancel()
                fadeTasks[key] = Task { @MainActor in
                    await fadeAnimator.applyFadeIn(image, to: marker, key: key)
                }
            }
        }
    }

    func scheduleAnimationRender(
        for key: MarkerGroupKey,
        current: Message,
        next: Message,
        progress: Double,
        currentMarkerForKey: @escaping () -> MarkerProtocol?
    ) {
        // 기존 렌더 취소 (프레임 누적 방지)
        renderTasks[key]?.cancel()

        renderTasks[key] = Task { @MainActor in
            // marker는 Task 안에서 다시 가져오도록 하기 (교체될 수 있으므로)
            guard let marker = currentMarkerForKey() else { return }

            let image = await renderer.renderRotatingBubble(
                current: current,
                next: next,
                progress: progress
            )

            if Task.isCancelled { return }
            guard let currentMarker = currentMarkerForKey(),
            currentMarker === marker else { return }

            marker.setIcon(image)
        }
    }
}
