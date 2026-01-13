//
//  NaverLocalItemDTO.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

import Foundation

struct NaverLocalSearchResponseDTO: Decodable, Sendable {
    let items: [NaverLocalItemDTO]
}

struct NaverLocalItemDTO: Decodable, Sendable {
    let title: String
    let category: String
    let address: String
    let roadAddress: String
    let mapx: String
    let mapy: String

    func toPlace() -> Place {
        let cleanName = title
            .strippingHTMLBoldTags()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // 네이버 응답엔 고유 ID가 없어서 "좌표+이름+도로명주소"로 key 생성
        let key = "\(mapx)|\(mapy)|\(cleanName)|\(roadAddress)"

        return Place(
            id: PlaceID(value: key),
            name: title.strippingHTMLBoldTags(),
            location: nil,
            address: address
        )
    }
}
