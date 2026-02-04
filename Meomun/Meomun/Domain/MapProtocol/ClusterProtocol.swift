//
//  ClusterProtocol.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

import Foundation

/// 클러스터 아이템(클러스터링 대상)의 추상 데이터
struct ClusterItem: Hashable {
    let id: Int
    let coordinate: Coordinate
    let tag: NSObject

    init(id: Int, coordinate: Coordinate, tag: NSObject) {
        self.id = id
        self.coordinate = coordinate
        self.tag = tag
    }
}

/// 클러스터러 포트.
/// map attach/detach + items 동기화만 담당.
protocol ClustererProtocol: AnyObject {
    func attach(to mapView: MapViewProtocol?)
    func setItems(_ items: [ClusterItem])
    func clear()
}
