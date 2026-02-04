//
//  DIErrorFallbackView.swift
//  Meomun
//
//  Created by hoon on 2/4/26.
//

import SwiftUI

struct DIErrorFallbackView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("앱을 초기화할 수 없어요")
                .font(.title3)
                .fontWeight(.semibold)

            Text("잠시 후 다시 실행해주세요.")
                .font(.body)
                .foregroundStyle(.secondary)

            Button("앱 종료") {
                exit(0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.mmBackground)
    }
}

#Preview {
    DIErrorFallbackView()
}
