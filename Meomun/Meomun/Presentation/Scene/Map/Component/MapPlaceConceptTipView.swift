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
        Text("지도에서 남긴 메시지를 확인해요.")
    }

    var message: Text? {
        Text("메시지를 탭하면 그 장소에 남겨진 메시지를 모아볼 수 있어요.")
    }

    var rules: [Rule] {
        #Rule(Self.$isReady) { $0 == true }
    }
}
