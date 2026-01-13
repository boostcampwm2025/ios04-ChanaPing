//
//  NaverGeocodeResponse.swift
//  Meomun
//
//  Created by 지연 on 1/13/26.
//

struct NaverGeocodeResponseDTO: Decodable, Sendable {
    let addresses: [AddressDTO]

    struct AddressDTO: Decodable, Sendable {
        let x: String
        let y: String
        let roadAddress: String?
        let jibunAddress: String?
    }
}
