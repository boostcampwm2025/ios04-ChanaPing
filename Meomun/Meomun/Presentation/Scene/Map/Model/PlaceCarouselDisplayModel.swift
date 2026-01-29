//
//  PlaceCarouselDisplayModel.swift
//  Meomun
//
//  Created by MinwooJe on 1/28/26.
//

/// 지도 캐러셀에 표시할 장소 정보를 담는 모델
struct PlaceCarouselDisplayModel: Identifiable, Hashable, Sendable {
    var id: PlaceID { place.id }
    let place: Place
    let messageCount: Int
}
