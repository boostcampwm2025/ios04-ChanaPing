//
//  TimelineIndicatorView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/23/26.
//

import SwiftUI

struct TimelineIndicatorView: View {
    enum Layout {
        static let lineWidth: CGFloat = 1
        static let nodeSize: CGFloat = 10
        static let columnWidth: CGFloat = 26
    }

    let height: CGFloat
    let showTopLine: Bool
    let showBottomLine: Bool

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.meomunSecondaryColor.opacity(showTopLine ? 0.35 : 0))
                .frame(width: Layout.lineWidth)
                .frame(maxHeight: .infinity)

            Circle()
                .strokeBorder(Color.meomunPointColor.opacity(0.7), lineWidth: 2)
                .background(Circle().fill(Color.clear))
                .frame(width: Layout.nodeSize, height: Layout.nodeSize)
                .padding(.vertical, 6)

            Rectangle()
                .fill(Color.meomunSecondaryColor.opacity(showBottomLine ? 0.35 : 0))
                .frame(width: Layout.lineWidth)
                .frame(maxHeight: .infinity)
        }
        .frame(width: Layout.columnWidth, height: height)
    }
}

#Preview {
    let height: CGFloat = 120
    VStack(spacing: 0) {
        TimelineIndicatorView(height: height, showTopLine: false, showBottomLine: true)
        TimelineIndicatorView(height: height, showTopLine: true, showBottomLine: true)
        TimelineIndicatorView(height: height, showTopLine: true, showBottomLine: true)
        TimelineIndicatorView(height: height, showTopLine: true, showBottomLine: true)
        TimelineIndicatorView(height: height, showTopLine: true, showBottomLine: false)

    }
}
