//
//  SearchNearbyPlaceUseCase.swift
//  Meomun
//
//  Created by 지연 on 1/14/26.
//

protocol SearchNearbyPlaceUseCase {
    func execute(
        query: String,
        userLocation: Coordinate,
        start: Int
    ) async throws -> [Place]
}

final class SearchNearbyPlaceUseCaseImpl: SearchNearbyPlaceUseCase {
    private let placeRepository: PlaceRepository

    init(
        placeRepository: PlaceRepository
    ) {
        self.placeRepository = placeRepository
    }

    func execute(
        query: String,
        userLocation: Coordinate,
        start: Int
    ) async throws -> [Place] {

        let candidates = try await placeRepository.searchPlace(query: query, start: start)

        let places: [Place] = candidates.compactMap { item -> Place? in
            // mapx = longitude, mapy = latitude
            // 네이버 Local Search API의 mapx, mapy는 WGS84이지만, 1e7(천만) 배 스케일된 정수값
            guard let doubleMapx = Double(item.mapx),
                  let doubleMapy = Double(item.mapy) else {
                return nil
            }

            let address = item.roadAddress.isEmpty ? item.address : item.roadAddress

            let normalizedAddress = address.normalizedKey()
            let rawId = "\(item.mapx)|\(item.mapy)|\(normalizedAddress)"

            return Place(
                id: PlaceID(value: rawId.sha256Hex()),
                name: item.title.strippingHTMLBoldTags(),
                coordinate: Coordinate(
                    latitude: doubleMapy / 10_000_000,
                    longitude: doubleMapx / 10_000_000
                ),
                address: address
            )
        }

        // 사용자 위치 기준 가까운 순 정렬
        return places
            .sorted {
                userLocation.distance(to: $0.coordinate) < userLocation.distance(to: $1.coordinate)
            }
    }
}
