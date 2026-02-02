//
//  MMToastView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/16/26.
//

import SwiftUI

struct MMToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.black.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
