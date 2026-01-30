//
//  FloatingTabItem.swift
//  Meomun
//
//  Created by 지연 on 1/6/26.
//

import SwiftUI

struct FloatingTabItem: View {
    let systemImageName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
                    .foregroundStyle(isSelected ? Color(.tabActive) : Color(.tabInactive))

                Circle()
                    .frame(width: 5, height: 5)
                    .foregroundStyle(isSelected ? Color(.tabActive) : .clear)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FloatingTabItem(systemImageName: "map", isSelected: true) {
        print("hi")
    }
}
