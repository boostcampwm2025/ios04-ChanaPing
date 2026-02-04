//
//  ClusterItemsBuilder.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

protocol ClusterItemsBuilding {
    func build(
        placeStore: [Coordinate: [Message]],
        noPlaceStore: [Coordinate: [Message]]
    ) -> [ClusterItem]
}

struct ClusterItemsBuilder: ClusterItemsBuilding {

    private let idProvider: ClusterIdProviding

    init(idProvider: ClusterIdProviding = ClusterIdProvider()) {
        self.idProvider = idProvider
    }

    func build(
        placeStore: [Coordinate: [Message]],
        noPlaceStore: [Coordinate: [Message]]
    ) -> [ClusterItem] {

        var items: [ClusterItem] = []
        items.reserveCapacity(placeStore.count + noPlaceStore.count)

        for (coord, messages) in placeStore where messages.isEmpty == false {
            let groupKey = MarkerGroupKey(coordinate: coord, isPlace: true)
            items.append(
                ClusterItem(
                    id: idProvider.id(for: groupKey),
                    coordinate: coord,
                    tag: ClusterItemTag.place
                )
            )
        }

        for (coord, messages) in noPlaceStore where messages.isEmpty == false {
            let groupKey = MarkerGroupKey(coordinate: coord, isPlace: false)
            items.append(
                ClusterItem(
                    id: idProvider.id(for: groupKey),
                    coordinate: coord,
                    tag: ClusterItemTag.noPlace
                )
            )
        }

        items.sort { $0.id < $1.id }
        return items
    }
}
