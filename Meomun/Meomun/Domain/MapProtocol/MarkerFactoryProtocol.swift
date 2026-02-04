//
//  MarkerFactoryProtocol.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

import Foundation

protocol MarkerFactoryProtocol {
    func makeMarker(coordinate: Coordinate) -> MarkerProtocol
}
