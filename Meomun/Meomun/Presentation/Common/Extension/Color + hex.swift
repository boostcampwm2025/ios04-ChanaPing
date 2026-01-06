//
//  Color + hex.swift
//  Meomun
//
//  Created by 송지연 on 12/22/25.
//

import SwiftUI

extension Color {
    static let meomunWriteButton = Color(hex: "#5C9397")
    static let meomunDefaultColor = Color(hex: "#0E1B1A")
    static let meomunPointColor = Color(hex: "#1DC9C0")
}

extension Color {
    init(hex: String) {
        let hex = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
