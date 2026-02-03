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
    }
}

struct SpaceIntroTip: Tip {
    @Parameter static var isReady: Bool = false

    var title: Text {
        Text("이 공간은 무엇인가요?")
    }

    var message: Text? {
        Text("이 장소에 남겨진 메시지 버블이 떠다니는 3D 공간이에요. 드래그로 둘러보고, 버블을 탭해 선택할 수 있어요.")
    }

    var image: Image? {
        Image(systemName: "sparkles")
    }

    var rules: [Rule] {
        #Rule(Self.$isReady) { $0 == true }
    }
}
