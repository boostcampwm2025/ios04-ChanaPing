//
//  PlaceCarouselCard.swift
//  Meomun
//
//  Created by MinwooJe on 1/28/26.
//

import SwiftUI

private enum Constants {
    static let padding: CGFloat = 20
    static let verticalSpacing: CGFloat = 8

    static let cornerRadius: CGFloat = 10

    static let addressTextOpacity: Double = 0.6
    static let messageCountTextOpacity: Double = 0.5
}

struct PlaceCarouselCard: View {
    private let item: PlaceCarouselDisplayModel

    init(item: PlaceCarouselDisplayModel) {
        self.item = item
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
            nameText

            addressText

            messageCountText
        }
        .padding(Constants.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
    }
}

// MARK: - Components

private extension PlaceCarouselCard {
    var nameText: some View {
        Text(item.place.name)
            .font(.title3.weight(.semibold))
            .foregroundStyle(Color.meomunPrimaryColor)
    }

    var addressText: some View {
        Text(item.place.address)
            .font(.subheadline)
            .foregroundStyle(Color.meomunPrimaryColor.opacity(Constants.addressTextOpacity))
    }

    var messageCountText: some View {
        Label {
            Text("\(item.messageCount)개의 메시지")
        } icon: {
            Image(systemName: "message")
        }
        .font(.footnote)
        .foregroundStyle(Color.meomunPrimaryColor.opacity(Constants.messageCountTextOpacity))
    }
}

#Preview {
    PlaceCarouselCard(
        item: PlaceCarouselDisplayModel(
            place: Place(
                id: PlaceID(value: "1"),
                name: "스타벅스 양재점",
                coordinate: Coordinate(latitude: 37.5, longitude: 127.0),
                address: "서울시 서초구 양재대로 123"
            ),
            messageCount: 12
        )
    )
    .padding()
    .background(Color.gray.opacity(0.2))
}
