//
//  MessageComposerPlaceConceptTipView.swift
//  Meomun
//
//  Created by hoon on 2/3/26.
//

import SwiftUI
import TipKit

struct MessageComposerPlaceConceptTip: Tip {
    @Parameter static var isReady: Bool = false

    var title: Text {
        Text("이 메세지는 ‘지금 머문 곳’에 남아요")
    }

    var message: Text? {
        Text("작성한 메시지는 현재 위치와 함께 저장돼요.")
    }

    var rules: [Rule] {
        [
            #Rule(Self.$isReady) { $0 == true }
        ]
    }
}
