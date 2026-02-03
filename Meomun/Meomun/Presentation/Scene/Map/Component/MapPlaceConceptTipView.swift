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
    }
}

struct MapPlaceConceptTip: Tip {
    @Parameter static var isReady: Bool = false

    var title: Text {
        Text("지도에 남긴 메세지를 찾아보세요!")
    }

    var message: Text? {
        Text("메세지를 탭하면 그 장소에 남겨진 메시지를 모아볼 수 있어요.")
    }

    var image: Image? {
        Image(systemName: "mappin.and.ellipse")
    }

    var rules: [Rule] {
        #Rule(Self.$isReady) { $0 == true }
    }
}
