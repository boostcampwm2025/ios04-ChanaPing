//
//  PolicyRepository.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

protocol PolicyRepository: Sendable {
    func getPolicy() async throws -> Policy
}
