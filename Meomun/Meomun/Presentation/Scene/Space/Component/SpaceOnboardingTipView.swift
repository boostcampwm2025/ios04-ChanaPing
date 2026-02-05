//
//  SpaceOnboardingTipView.swift
//  Meomun
//
//  Created by hoon on 2/3/26.
//

import SwiftUI
import TipKit

struct SpaceOnboardingTipView: View {
    var body: some View {
        TipView(SpaceIntroTip(), arrowEdge: .top)
            .padding(.top, 12)
            .padding(.horizontal, 16)
            .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 6)
    }
}

struct SpaceIntroTip: Tip {
    @Parameter static var isReady: Bool = false

    var title: Text {
        Text("나만의 공간을 확인해요.")
    }

    var message: Text? {
        Text("이 장소에 남겨진 메시지 버블이 떠다니는 공간이에요. 드래그로 둘러보고, 버블을 눌러 삭제할 수 있어요.")
    }

    var rules: [Rule] {
        #Rule(Self.$isReady) { $0 == true }
    }
}
