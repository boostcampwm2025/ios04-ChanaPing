//
//  MessageComposerPlaceConceptTipView.swift
//  Meomun
//
//  Created by hoon on 2/3/26.
//

import SwiftUI
import TipKit

struct MessageComposerPlaceConceptTipView: View {
    var body: some View {
        TipView(MessageComposerPlaceConceptTip(), arrowEdge: .top)
            .padding(.top, 4)
            .padding(.horizontal, 4)
    }
}

struct MessageComposerPlaceConceptTip: Tip {
    @Parameter static var isReady: Bool = false

    var title: Text {
        Text("이 말은 ‘지금 머문 곳’에 남아요")
    }

    var message: Text? {
        Text("작성한 메시지는 현재 위치(머문 장소)와 함께 저장돼요. 장소를 선택하면 더 정확해져요.")
    }

    var image: Image? {
        Image(systemName: "mappin.and.ellipse")
    }

    var rules: [Rule] {
        [
            #Rule(Self.$isReady) { $0 == true }
        ]
    }
}
