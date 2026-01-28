//
//  MapCameraSnapshot.swift
//  Meomun
//
//  Created by 지연 on 1/28/26.
//

struct MapCameraSnapshot: Equatable {
    let coordinate: Coordinate
    let zoom: Double
    let tilt: Double
    let heading: Double

    init(
        coordinate: Coordinate,
        zoom: Double = 17,
        tilt: Double = 45,
        heading: Double = 0
    ) {
        self.coordinate = coordinate
        self.zoom = zoom
        self.tilt = tilt
        self.heading = heading
    }
}
