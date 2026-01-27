//
//  TimelineIndicatorView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/23/26.
//

import SwiftUI

/// 타임라인 행의 선택 상태를 의미합니다.
enum TimelineSelectionState {
    /// 편집 모드 비활성화 -> 기본 노드
    case inactive

    /// 편집 모드, 미선택 -> 회색 원
    case unselected

    /// 편집 모드, 선택됨 -> 체크 마크
    case selected
}

struct TimelineIndicatorView: View {
    enum Layout {
        static let lineWidth: CGFloat = 1
        static let nodeSize: CGFloat = 10
        static let columnWidth: CGFloat = 26
    }

    let height: CGFloat
    let showTopLine: Bool
    let showBottomLine: Bool
    private let selectionState: TimelineSelectionState

    init(height: CGFloat, showTopLine: Bool, showBottomLine: Bool, selectionState: TimelineSelectionState = .inactive) {
        self.height = height
        self.showTopLine = showTopLine
        self.showBottomLine = showBottomLine
        self.selectionState = selectionState
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.meomunSecondaryColor.opacity(showTopLine ? 0.35 : 0))
                .frame(width: Layout.lineWidth)
                .frame(maxHeight: .infinity)

            indicator

            Rectangle()
                .fill(Color.meomunSecondaryColor.opacity(showBottomLine ? 0.35 : 0))
                .frame(width: Layout.lineWidth)
                .frame(maxHeight: .infinity)
        }
        .frame(width: Layout.columnWidth, height: height)
    }
}

extension TimelineIndicatorView {
    private var indicator: some View {
        Group {
            switch selectionState {
            case .inactive:
                Circle()
                    .strokeBorder(Color.meomunPointColor.opacity(0.7), lineWidth: 2)
                    .background(Circle().fill(Color.clear))
                    .frame(width: Layout.nodeSize, height: Layout.nodeSize)
                    .padding(.vertical, 6)

            case .unselected:
                Circle()
                    .strokeBorder(Color.meomunSecondaryColor, lineWidth: 1.5)
                    .frame(width: Layout.nodeSize * 2.5, height: Layout.nodeSize * 2.5)

            case .selected:
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .foregroundStyle(Color.meomunPointColor.opacity(0.7))
                    .frame(width: Layout.nodeSize * 2.5, height: Layout.nodeSize * 2.5)
            }
        }
    }
}

#Preview {
    let height: CGFloat = 120
    VStack(spacing: 0) {
        TimelineIndicatorView(height: height, showTopLine: false, showBottomLine: true, selectionState: .inactive)
        TimelineIndicatorView(height: height, showTopLine: true, showBottomLine: true, selectionState: .unselected)
        TimelineIndicatorView(height: height, showTopLine: true, showBottomLine: true, selectionState: .selected)
        TimelineIndicatorView(height: height, showTopLine: true, showBottomLine: true, selectionState: .unselected)
        TimelineIndicatorView(height: height, showTopLine: true, showBottomLine: false, selectionState: .unselected)

    }
}
