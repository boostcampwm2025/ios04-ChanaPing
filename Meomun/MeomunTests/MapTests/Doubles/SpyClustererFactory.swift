//
//  SpyClustererFactory.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

@testable import Meomun

final class SpyClustererFactory: ClustererFactoryProtocol {
    private(set) var makeCount = 0
    let clusterer = SpyClusterer()

    func makeClusterer() -> ClustererProtocol {
        makeCount += 1
        return clusterer
    }
}
