//
//  ReverseGeocodeDTO.swift
//  Meomun
//
//  Created by 지연 on 1/23/26.
//

struct ReverseGeocodeResponseDTO: Decodable, Sendable {
    let status: StatusDTO?
    let results: [ResultDTO]?
}

struct StatusDTO: Decodable, Sendable {
    let code: Int?
    let name: String?
    let message: String?
}

struct ResultDTO: Decodable, Sendable {
    let name: String?
    let region: RegionDTO?
    let land: LandDTO?
}

struct RegionDTO: Decodable, Sendable {
    let area0: AreaDTO?
    let area1: AreaDTO?
    let area2: AreaDTO?
    let area3: AreaDTO?
    let area4: AreaDTO?
}

struct AreaDTO: Decodable, Sendable {
    let name: String?
}

struct LandDTO: Decodable, Sendable {
    let name: String?          // 도로명
    let number1: String?       // 본번
    let number2: String?       // 부번
    let addition0: AdditionDTO? // 건물번호 등
    let addition1: AdditionDTO?
    let addition2: AdditionDTO?
}

struct AdditionDTO: Decodable, Sendable {
    let value: String?
}
