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
}
