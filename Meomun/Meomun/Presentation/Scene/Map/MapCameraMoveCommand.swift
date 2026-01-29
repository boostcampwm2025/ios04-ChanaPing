//
//  MapCameraMoveCommand.swift
//  Meomun
//
//  Created by 지연 on 1/29/26.
//

struct MapCameraMoveCommand: Equatable {
    enum Reason: Equatable { case restore, userAction }
    let snapshot: MapCameraSnapshot
    let reason: Reason
}
