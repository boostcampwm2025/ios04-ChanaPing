//
//  AlertState.swift
//  Meomun
//
//  Created by Hayeon Park on 1/20/26.
//

import Foundation

struct AlertModel: Identifiable, Equatable {
    let id: UUID
    let title: String
    let message: String
    let buttons: [AlertButtonConfig]

    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        buttons: [AlertButtonConfig] = [.confirm]
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.buttons = Array(buttons.prefix(2))
    }

    static func == (lhs: AlertModel, rhs: AlertModel) -> Bool {
        lhs.id == rhs.id
        && lhs.title == rhs.title
        && lhs.message == rhs.message
    }
}
