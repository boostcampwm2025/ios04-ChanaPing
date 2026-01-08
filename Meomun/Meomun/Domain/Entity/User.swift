//
//  User.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

struct User: Identifiable, Sendable {
    let id: UserID
    let reportMessageIDs: [MessageID] = []
}
