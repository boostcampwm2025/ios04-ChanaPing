//
//  StackBack.swift
//  Meomun
//
//  Created by 지연 on 1/26/26.
//

import SwiftUI

struct StackBack: View {
    let bubbleWidth: CGFloat
    let bubbleHeight: CGFloat = 103

    private let offset1: CGSize = .init(width: 14, height: 14)
    private let offset2: CGSize = .init(width: 7, height: 7)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.gray)
                .fill(Color(hex: "E6E6E6"))
                .offset(offset1)
            
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.gray)
                .fill(Color(hex: "F4F4F4"))
                .offset(offset2)
        }
        .frame(width: bubbleWidth, height: bubbleHeight)
        .allowsHitTesting(false)
        .zIndex(0)
    }
}

#Preview {
    StackBack(bubbleWidth: 180)
}
