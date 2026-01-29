//
//  Array+extension.swift
//  Meomun
//
//  Created by Hayeon Park on 1/29/26.
//

extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
