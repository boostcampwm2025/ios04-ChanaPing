//
//  LeaveMessageView.swift
//  Meomun
//
//  Created by Hayeon Park on 1/6/26.
//

import SwiftUI

fileprivate enum Constants {
    static let navigationTitle = "잠시 남겨놓기"
    static let textEditorTitle = "이 말은 잠시 머물 거에요."
    static let textEditorPlaceholder = "지금 어디에 있나요?"
}

struct LeaveMessageView: View {
    @State private var message: String = ""
    @State private var placeText: String = ""

    private var suggestPlaces: [String] = ["스타벅스 파주가람점", "ONUTE", "콰이어트라이트", "메가MGC커피 파주별하람마을점"]

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            ZStack {
                Text(Constants.navigationTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.meomunPrimaryColor)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack {
                    BackButton(action: {})
                    Spacer()
                }
            }
            .frame(height: 44)

            Spacer(minLength: 0)

            Text(Constants.textEditorTitle)
                .font(.headline.bold())
                .foregroundStyle(Color.meomunSecondaryColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            MessageTextEditor(text: $message)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                PlaceSearchContainerView {
                    NavigationLink {
                        SearchPlaceView()
                    } label: {
                        Text(Constants.textEditorPlaceholder)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(.placeholderText))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                CancelButton {
                    placeText = ""
                }
            }

            PlaceTagSlider(places: suggestPlaces) { selected in
                placeText = selected
            }

            Spacer(minLength: 0)

            ConfirmButton(action: {})
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .background {
            Image(.background)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }
}

#Preview {
    @Previewable @State var message: String = ""

    NavigationStack {
        LeaveMessageView()
    }
}
