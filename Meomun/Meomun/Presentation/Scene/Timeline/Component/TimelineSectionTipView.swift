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
            .padding(.top, 3)
            .padding(.horizontal, 16)
            .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 6)
    }
}

struct TimelineSectionTip: Tip {
    @Parameter static var isReady: Bool = false
    @Parameter static var hasContent: Bool = false
    @Parameter static var isEditing: Bool = false

    var title: Text {
        Text("지금까지 남긴 말들이 모여있어요.")
    }

    var message: Text? {
        Text("월 별로 남긴 말들의 흔적을 따라가보세요!")
    }

    var rules: [Rule] {
        [
            #Rule(Self.$isReady) { $0 == true },
            #Rule(Self.$hasContent) { $0 == true },
            #Rule(Self.$isEditing) { $0 == false }
        ]
    }
}
