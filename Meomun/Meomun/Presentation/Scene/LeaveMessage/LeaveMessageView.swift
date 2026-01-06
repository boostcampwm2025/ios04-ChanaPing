//
//  LeaveMessageView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/6/26.
//

import SwiftUI

struct LeaveMessageView: View {
    @State private var message: String = ""
    @State private var placeText: String = ""

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            BackButton(action: {})

            Spacer()

            Text("이 말은 잠시 머물거에요.")
                .font(.headline.bold())
                .foregroundStyle(Color.meomunSecondaryColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            MessageTextEditor(text: $message)

            Spacer()

            HStack(spacing: 8) {
                PlaceTextField(text: $placeText)
                SearchButton(action: {})
                CancelButton(action: {})
            }

            Spacer()

            ConfirmButton(action: {})

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    @Previewable @State var message: String = ""

    LeaveMessageView()
}
