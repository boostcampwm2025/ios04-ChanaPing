//
//  UserRepository.swift
//  Meomun
//
//  Created by Hayeon Park on 1/8/26.
//

protocol UserRepository: Sendable {
    func getUser() async throws -> User
    func withdrawUser() async throws
}
