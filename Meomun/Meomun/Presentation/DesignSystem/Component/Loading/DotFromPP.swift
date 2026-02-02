//
//  DotFromPP.swift
//  Meomun
//
//  Created by 지연 on 2/2/26.
//

import SwiftUI

struct DotFromPP: View {
    let xCentimeters: CGFloat
    let yCentimeters: CGFloat

    var diameter: CGFloat = 12
    var color: Color = .teal

    var body: some View {
        GeometryReader { proxy in
            let xPoints = UnitConverter.cmToPoints(xCentimeters)
            let yPoints = UnitConverter.cmToPoints(yCentimeters)

            Circle()
                .fill(color)
                .frame(width: diameter, height: diameter)
                .position(
                    x: xPoints + diameter / 2,
                    y: yPoints + diameter / 2
                )
                .clipped()
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

private enum UnitConverter {
    static let pointsPerCentimeter: CGFloat = 72.0 / 2.54
    static func cmToPoints(_ centimeters: CGFloat) -> CGFloat {
        centimeters * pointsPerCentimeter
    }
}
