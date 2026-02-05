//
//  MapPlaceConceptTipView.swift
//  Meomun
//
//  Created by hoon on 2/3/26.
//

import SwiftUI
import TipKit

struct MapPlaceConceptTipView: View {
    var body: some View {
        TipView(MapPlaceConceptTip())
            .padding(.top, 12)
            .padding(.horizontal, 16)
            .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 6)
    }
}

struct MapPlaceConceptTip: Tip {
    @Parameter static var isReady: Bool = false

    var title: Text {
        Text("첫 메시지를 남겨보세요!")
    }

    var message: Text? {
        Text("지금 떠오르는 말 그대로 적어보아요.")
    }

    var rules: [Rule] {
        #Rule(Self.$isReady) { $0 == true }
    }
}
