//
//  MiniMapViewController.swift
//  Meomun
//
//  Created by Hayeon Park on 1/29/26.
//

import UIKit
import NMapsMap

final class MiniMapViewController: UIViewController {
    // MARK: - Init
    private let miniMapView: NMFMapView = {
        let miniMapView = NMFMapView()

        // 지도 UI 설정
        miniMapView.logoInteractionEnabled = false

        // 유저 상호작용
        miniMapView.isUserInteractionEnabled = false

        // 최소 및 최대 줌 레벨 설정
        miniMapView.minZoomLevel = 5
        miniMapView.maxZoomLevel = 18

        miniMapView.customStyleId = "bf0bd9ae-f750-4895-8246-2744297005d0"

        return miniMapView
    }()

    private var markers: [NMFMarker] = []
    private var pathOverlay: NMFPath?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        configureLayout()
    }
}

// MARK: - Configure UI

extension MiniMapViewController {
    private func configureSubviews() {
        view.addSubview(miniMapView)
        miniMapView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            miniMapView.topAnchor.constraint(equalTo: view.topAnchor),
            miniMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            miniMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            miniMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

