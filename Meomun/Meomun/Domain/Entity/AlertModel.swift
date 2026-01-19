//
//  AlertState.swift
//  Meomun
//
//  Created by Hayeon Park on 1/20/26.
//

import Foundation

struct AlertModel: Identifiable, Equatable {
    let id: UUID = UUID()
    let title: String
    let message: String
}
