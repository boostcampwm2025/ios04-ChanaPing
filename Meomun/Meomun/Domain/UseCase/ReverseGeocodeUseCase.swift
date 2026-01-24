//
//  ReverseGeocodeUseCase.swift
//  Meomun
//
//  Created by 지연 on 1/23/26.
//

import Foundation

enum ReverseGeocodeUseCaseError: Error {
    case emptyResult
}

protocol ReverseGeocodeUseCase: Sendable {
    /// 도로명 우선 → 없으면 지번
    func execute(longitude: Double, latitude: Double) async throws -> String
}

final class ReverseGeocodeUseCaseImpl: ReverseGeocodeUseCase {
    private let repository: ReverseGeocodeRepository

    init(repository: ReverseGeocodeRepository) {
        self.repository = repository
    }

    func execute(longitude: Double, latitude: Double) async throws -> String {
        let dto = try await repository.fetchAddress(longitude: longitude, latitude: latitude)

        guard let results = dto.results, !results.isEmpty else {
            throw ReverseGeocodeUseCaseError.emptyResult
        }

        // 1) roadaddr(도로명) 우선
        if let road = results.first(where: { $0.name == "roadaddr" }),
           let address = buildRoadAddress(from: road) {
            return address
        }

        // 2) 없으면 addr(지번) (행정구역 기반 조합)
        if let jibun = results.first(where: { $0.name == "addr" }),
           let address = buildJibunAddress(from: jibun) {
            return address
        }

        // 3) 그래도 없으면 region이라도 붙여서 반환
        if let fallback = results.first,
           let address = buildRegionOnly(from: fallback) {
            return address
        }

        throw ReverseGeocodeUseCaseError.emptyResult
    }

    private func buildRoadAddress(from result: ResultDTO) -> String? {
        guard let region = result.region else { return nil }

        let area1 = region.area1?.name
        let area2 = region.area2?.name
        let area3 = region.area3?.name

        // 도로명 + 번지(또는 건물번호)
        let roadName = result.land?.name
        let number1 = result.land?.number1
        let number2 = result.land?.number2

        let main = [area1, area2, area3].compactMap { $0 }.joined(separator: " ")
        var tail = [roadName].compactMap { $0 }.joined(separator: " ")

        // number1/2 조합 (있을 때만)
        if let number1, !number1.isEmpty {
            if let number2, !number2.isEmpty, number2 != "0" {
                tail += " \(number1)-\(number2)"
            } else {
                tail += " \(number1)"
            }
        }

        let address = [main, tail].filter { !$0.isEmpty }.joined(separator: " ")
        return address.isEmpty ? nil : address
    }

    private func buildJibunAddress(from result: ResultDTO) -> String? {
        guard let region = result.region else { return nil }
        let area1 = region.area1?.name
        let area2 = region.area2?.name
        let area3 = region.area3?.name
        let area4 = region.area4?.name

        let address = [area1, area2, area3, area4].compactMap { $0 }.joined(separator: " ")
        return address.isEmpty ? nil : address
    }

    private func buildRegionOnly(from result: ResultDTO) -> String? {
        guard let region = result.region else { return nil }
        let address = [
            region.area1?.name,
            region.area2?.name,
            region.area3?.name,
            region.area4?.name
        ]
        .compactMap { $0 }
        .joined(separator: " ")

        return address.isEmpty ? nil : address
    }
}
