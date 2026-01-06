//
//  Store.swift
//  Meomun
//
//  Created by 지연 on 1/6/26.
//

import Foundation

protocol Store: AnyObject, ObservableObject {
    associatedtype Intent
    associatedtype Action
    associatedtype State

    var state: State { get set }

    func action(intent: Intent) -> AsyncStream<Action>
    func reduce(state: State, action: Action) -> State
}

extension Store {
    @MainActor
    func send(intent: Intent) async {
        let actions = action(intent: intent)
        for await action in actions {
            state = reduce(state: state, action: action)
        }
    }
}
