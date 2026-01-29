//
//  MarkerAssets.swift
//  Meomun
//
//  Created by Hayeon Park on 1/29/26.
//

import UIKit
import NMapsMap

enum MarkerAssets {
    static let mappin: NMFOverlayImage = {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)

        let uiImage = UIImage(systemName: "mappin", withConfiguration: config)?
            .withTintColor(.systemRed, renderingMode: .alwaysOriginal)

        return NMFOverlayImage(image: uiImage ?? UIImage())
    }()

    static let pin: NMFOverlayImage = {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)

        let uiImage = UIImage(systemName: "pin.fill", withConfiguration: config)?
            .withTintColor(.systemRed, renderingMode: .alwaysOriginal)

        return NMFOverlayImage(image: uiImage ?? UIImage())
    }()
}
