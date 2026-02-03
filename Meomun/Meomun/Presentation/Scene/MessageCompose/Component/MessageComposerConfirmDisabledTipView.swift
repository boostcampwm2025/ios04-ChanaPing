//
//  MessageComposerConfirmDisabledTipView.swift
//  Meomun
//
//  Created by hoon on 2/3/26.
//

import SwiftUI
import TipKit

struct MessageComposerConfirmDisabledTipView: View {
    var body: some View {
        TipView(MessageComposerConfirmDisabledTip(), arrowEdge: .bottom)
            .padding(.top, 4)
            .padding(.horizontal, 4)
    }
}

struct MessageComposerConfirmDisabledTip: Tip {
    @Parameter static var isReady: Bool = false
    @Parameter static var shouldShow: Bool = false
    @Parameter static var hasStartedTyping: Bool = false

    var title: Text {
        Text("‘확인’이 아직 비활성화예요")
    }

    var message: Text? {
        Text("메시지를 입력하면 ‘확인’ 버튼이 활성화돼요.")
    }

    var image: Image? {
        Image(systemName: "checkmark.circle")
    }

    var rules: [Rule] {
        [
            #Rule(Self.$isReady) { $0 == true },
            #Rule(Self.$shouldShow) { $0 == true },
            #Rule(Self.$hasStartedTyping) { $0 == false }
        ]
    }
}
