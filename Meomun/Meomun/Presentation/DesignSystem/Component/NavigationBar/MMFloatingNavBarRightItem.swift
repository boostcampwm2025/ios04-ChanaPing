//
//  MMFloatingNavBarRightItem.swift
//  Meomun
//
//  Created by 지연 on 2/2/26.
//

enum MMFloatingNavBarRightItem: Equatable {
    case search(action: () -> Void)
    case edit(isEditing: Bool, action: () -> Void)
    case none

    static func == (lhs: MMFloatingNavBarRightItem, rhs: MMFloatingNavBarRightItem) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none): return true
        case (.search, .search): return true
        case (.edit(let before, _), .edit(let after, _)): return before == after
        default: return false
        }
    }
}

struct MMFloatingNavBarConfiguration: Equatable {
    let title: String
    let rightItem: MMFloatingNavBarRightItem
}
