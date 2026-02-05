//
//  MapPlaceConceptTipView.swift
//  Meomun
//
//  Created by hoon on 2/3/26.
//

import SwiftUI
import TipKit

struct MapPlaceConceptTip: Tip {
    @Parameter static var isReady: Bool = false

    var title: Text {
        Text("첫 메시지를 남겨보세요!")
    }

    var message: Text? {
        Text("남긴 메시지를 눌러 그 장소의 기록을\n모아보아요!")
    }

    var rules: [Rule] {
        #Rule(Self.$isReady) { $0 == true }
    }
}
