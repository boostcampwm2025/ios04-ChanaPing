//
//  MainMapViewWrapper.swift
//  Fleeting-Prototype
//
//  Created by MinwooJe on 12/18/25.
//

import SwiftUI

struct MainMapViewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MainMapViewController {
        let viewController = MainMapViewController()
        return viewController
    }

    func updateUIViewController(_ uiViewController: MainMapViewController, context: Context) { }
}
