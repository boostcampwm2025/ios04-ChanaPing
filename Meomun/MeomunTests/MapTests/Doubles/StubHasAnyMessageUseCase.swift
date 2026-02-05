//
//  StubHasAnyMessageUseCase.swift
//  Meomun
//
//  Created by 지연 on 2/5/26.
//

import Foundation
@testable import Meomun

final class StubHasAnyMessageUseCase: HasAnyMessageUseCase {
    func execute() async throws -> Bool {
        return true
    }
}
