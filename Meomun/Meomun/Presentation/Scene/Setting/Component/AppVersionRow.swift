//
//  AppVersionRow.swift
//  Meomun
//
//  Created by hoon on 1/28/26.
//

import SwiftUI

struct AppVersionRow: View {
    private var versionText: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        switch (shortVersion, buildNumber) {
        case let (.some(version), .some(build)):
            return "v\(version) (\(build))"
        case let (.some(version), .none):
            return "v\(version)"
        case let (.none, .some(build)):
            return "build \(build)"
        default:
            return "-"
        }
    }

    var body: some View {
        HStack {
            Text("앱 버전")
            Spacer()
            Text(versionText)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("앱 버전")
        .accessibilityValue(versionText)
    }
}
