//
//  PlaceCarousel.swift
//  Meomun
//
//  Created by MinwooJe on 1/28/26.
//

import SwiftUI

private enum Constants {
    // Page Indicator
    static let pageIndicatorSize: CGFloat = 6
    static let pageIndicatorSpacing: CGFloat = 6
    static let pageIndicatorVerticalPadding: CGFloat = 6
    static let pageIndicatorHorizontalPadding: CGFloat = 12

    static let pageIndicatorBackOpacity: CGFloat = 0.15

    // Carousel
    static let verticalSpacing: CGFloat = 8

    static let carouselHeight: CGFloat = 120
}

struct PlaceCarousel: View {
    private let items: [PlaceCarouselDisplayModel]
    private let onTapped: (Place) -> Void

    init(items: [PlaceCarouselDisplayModel], onTapped: @escaping (Place) -> Void) {
        self.items = items
        self.onTapped = onTapped
    }

    @State private var currentIndex: Int = 0

    var body: some View {
        VStack(spacing: Constants.verticalSpacing) {
            carouselContent

            if items.count > 1 {
                pageIndicator
            }
        }
    }
}

// MARK: - Components

private extension PlaceCarousel {
    var pageIndicator: some View {
        HStack(spacing: Constants.pageIndicatorSpacing) {
            ForEach(0..<items.count, id: \.self) { index in
                Circle()
                    .fill(
                        index == currentIndex
                        ? Color.mmPoint
                        : Color.mmPrimary.opacity(0.2)
                    )
                    .frame(width: Constants.pageIndicatorSize, height: Constants.pageIndicatorSize)
            }
        }
        .padding(.horizontal, Constants.pageIndicatorHorizontalPadding)
        .padding(.vertical, Constants.pageIndicatorVerticalPadding)
        .background(
            Capsule()
                .fill(Color.gray.opacity(Constants.pageIndicatorBackOpacity))
        )
    }

    var carouselContent: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                PlaceCarouselCard(item: item)
                    .onTapGesture {
                        onTapped(item.place)
                    }
                    .tag(index)
                    .padding(.horizontal, MMSpacing.floatingHorizontalPadding)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: Constants.carouselHeight)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        VStack {
            Spacer()

            PlaceCarousel(
                items: [
                    PlaceCarouselDisplayModel(
                        place: Place(
                            id: PlaceID(value: "1"),
                            name: "스타벅스 양재점",
                            coordinate: Coordinate(latitude: 37.5, longitude: 127.0),
                            address: "서울시 서초구 양재대로 123"
                        ),
                        messageCount: 12
                    ),
                    PlaceCarouselDisplayModel(
                        place: Place(
                            id: PlaceID(value: "2"),
                            name: "투썸플레이스 양재점",
                            coordinate: Coordinate(latitude: 37.5, longitude: 127.0),
                            address: "서울시 서초구 양재대로 125"
                        ),
                        messageCount: 5
                    )
                ],
                onTapped: { place in
                    print("Selected: \(place.name)")
                }
            )
        }
    }
}
