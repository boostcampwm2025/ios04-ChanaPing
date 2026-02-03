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
    }
}

struct TimelineSectionTip: Tip {
    @Parameter static var isReady: Bool = false
    @Parameter static var hasContent: Bool = false
    @Parameter static var isEditing: Bool = false

    var title: Text {
        Text("월별 기록을 한눈에")
    }

    var message: Text? {
        Text("상단의 월(YYYY.MM) 옆 흔전 따라가기를 탭하면 해당 달의 기록을 모아볼 수 있어요.")
    }

    var image: Image? {
        Image(systemName: "calendar")
    }

    var rules: [Rule] {
        [
            #Rule(Self.$isReady) { $0 == true },
            #Rule(Self.$hasContent) { $0 == true },
            #Rule(Self.$isEditing) { $0 == false }
        ]
    }
}
