//
//  TimelineSectionTipView.swift
//  Meomun
//
//  Created by hoon on 2/3/26.
//

import SwiftUI
import TipKit

struct TimelineSectionTipView: View {
    var body: some View {
        TipView(TimelineSectionTip(), arrowEdge: .top)
            .padding(.top, 12)
            .padding(.horizontal, 16)
            .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 6)
    }
}

struct TimelineSectionTip: Tip {
    @Parameter static var isReady: Bool = false
    @Parameter static var hasContent: Bool = false
    @Parameter static var isEditing: Bool = false

    var title: Text {
        Text("시간 순으로 기록을 확인해요.")
    }

    var message: Text? {
        Text("흔적 따라가기를 탭하면 해당 달의 기록을 모아볼 수 있어요.")
    }

    var rules: [Rule] {
        [
            #Rule(Self.$isReady) { $0 == true },
            #Rule(Self.$hasContent) { $0 == true },
            #Rule(Self.$isEditing) { $0 == false }
        ]
    }
}
