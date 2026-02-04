//
//  NaverClustererFactory.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

import UIKit
import NMapsMap

struct NaverClustererFactory: ClustererFactoryProtocol {
    let leaf: NMCLeafMarkerUpdater
    let cluster: NMCClusterMarkerUpdater

    func makeClusterer() -> ClustererProtocol {
        NaverClustererAdapter(leafUpdater: leaf, clusterUpdater: cluster)
    }
}
