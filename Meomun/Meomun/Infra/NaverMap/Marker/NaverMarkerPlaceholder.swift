//
//  NaverMarkerPlaceholder.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

import UIKit
import NMapsMap

enum NaverMarkerPlaceholder {
    static let transparent1px: UIImage = {
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }

        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }()

    static let overlayImage: NMFOverlayImage = {
        NMFOverlayImage(image: transparent1px)
    }()
}
