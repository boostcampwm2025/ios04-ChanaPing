//
//  ClusterIdProvider.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

protocol ClusterIdProviding {
    func id(for groupKey: MarkerGroupKey) -> Int
}

struct ClusterIdProvider: ClusterIdProviding {
    func id(for groupKey: MarkerGroupKey) -> Int {
        // 1e-7 deg ≈ 1.1cm (offset이 수m 수준이면 절대 안 뭉침)
        let scale = 10_000_000.0

        // lat: -90...+90, lng: -180...+180
        let latQ = Int64((groupKey.coordinate.latitude * scale).rounded())
        let lngQ = Int64((groupKey.coordinate.longitude * scale).rounded())

        // 양수화 (범위 안이면 안전)
        let latShifted = latQ + Int64(90 * Int(scale))    // 0 .. 180*scale
        let lngShifted = lngQ + Int64(180 * Int(scale))   // 0 .. 360*scale

        // latShifted: 최대 1,800,000,000 (31bit)
        // lngShifted: 최대 3,600,000,000 (32bit)
        // [isPlace 1bit | lat 31bit | lng 32bit] = 64bit
        let placeBit: Int64 = groupKey.isPlace ? 1 : 0
        let packed = (placeBit << 63)
        | ((latShifted & 0x7FFF_FFFF) << 32)
        | (lngShifted & 0xFFFF_FFFF)

        return Int(truncatingIfNeeded: packed)
    }
}
