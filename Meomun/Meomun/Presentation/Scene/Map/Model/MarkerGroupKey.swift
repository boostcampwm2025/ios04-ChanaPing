//
//  MarkerGroupKey.swift
//  Meomun
//
//  Created by MinwooJe on 1/14/26.
//

/// 마커 구분을 위한 복합 키 (좌표 + 마커 타입)
struct MarkerGroupKey: Hashable {
    let coordinate: Location
    let isPlace: Bool
}
