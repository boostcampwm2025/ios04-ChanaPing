//
//  NaverClustererFactory.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

import UIKit
import NMapsMap

public struct NaverClustererFactory: ClustererFactoryProtocol {
    private let leaf: NMCLeafMarkerUpdater
    private let cluster: NMCClusterMarkerUpdater

    public init(leaf: NMCLeafMarkerUpdater, cluster: NMCClusterMarkerUpdater) {
        self.leaf = leaf
        self.cluster = cluster
    }

    public func makeClusterer() -> ClustererProtocol {
        NaverClustererAdapter(leafUpdater: leaf, clusterUpdater: cluster)
    }
}
