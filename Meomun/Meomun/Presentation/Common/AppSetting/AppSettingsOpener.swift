//
//  AppSettingsOpener.swift
//  Meomun
//
//  Created by hoon on 1/29/26.
//

import UIKit

struct AppSettingsOpener: AppSettingsOpening {
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
