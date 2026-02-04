//
//  MarkerTapRoute.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

protocol MarkerTapRouting {
    func route(isPlaceMarker: Bool, messages: [Message]) -> MarkerTapRoute?
}

enum MarkerTapRoute {
    case place(messages: [Message])
    case noPlace(messages: [Message])
}

/// 기본 정책:
/// - Place 마커 탭: placeTag가 nil이 아닌 메시지만 대상으로,
///   '서로 다른 placeTag가 1개'일 때만 place 탭 허용
/// - NoPlace 마커 탭: 그냥 전달
struct MarkerTapRoutingPolicy: MarkerTapRouting {
    func route(isPlaceMarker: Bool, messages: [Message]) -> MarkerTapRoute? {
        if isPlaceMarker {
            let placeMessages = messages.filter { $0.placeTag != nil }
            guard !placeMessages.isEmpty else { return nil }

            let uniquePlaces = Set(placeMessages.compactMap { $0.placeTag })
            guard uniquePlaces.count == 1 else { return nil }

            return .place(messages: placeMessages)
        } else {
            return .noPlace(messages: messages)
        }
    }
}
