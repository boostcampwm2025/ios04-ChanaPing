//
//  DomeScreen.swift
//  Fleeting-Prototype
//
//  Created by Daehoon Lee on 12/18/25.
//

import SwiftUI

struct DomeScreen: View {
    @State private var dragDelta: Float = 0

    var body: some View {
        DomeView(
            modelFileName: "Dome",
            modelFileExtension: "usdz",
            dragDelta: dragDelta
        )
        .ignoresSafeArea()
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    dragDelta = Float(value.translation.width) * 0.001
                }
                .onEnded { _ in
                    dragDelta = 0
                }
        )
    }
}

#Preview {
    DomeScreen()
}
