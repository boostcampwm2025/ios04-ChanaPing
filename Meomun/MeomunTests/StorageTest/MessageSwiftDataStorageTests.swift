//
//  MessageSwiftDataStorageTests.swift
//  Meomun
//
//  Created by Hayeon Park on 2/2/26.
//

import Testing
import SwiftData
@testable import Meomun

// MARK: - MessageSwiftDataStorageTests

@Suite
struct MessageSwiftDataStorageTests {

    // MARK: - Helpers

    private func makeInMemoryContainer() throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: AppDataConfig.schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )
        return try ModelContainer(for: AppDataConfig.schema, configurations: [config])
    }

    private func makeStorage() -> MessageSwiftDataStorage {
        // 테스트마다 새 인스턴스를 만들어서 격리.
        MessageSwiftDataStorage()
    }

    private func makeCreateDTO(
        content: String,
        latitude: Double = 37.0,
        longitude: Double = 127.5,
        address: String = "서울",
        place: PlaceDTO? = nil
    ) -> CreateMessageRequestDTO {
        CreateMessageRequestDTO(
            content: content,
            latitude: latitude,
            longitude: longitude,
            address: address,
            place: place
        )
    }

    private func makePlaceDTO(
        id: String = "place-1",
        name: String = "카페",
        latitude: Double = 37.0,
        longitude: Double = 127.0,
        address: String = "서울"
    ) -> PlaceDTO {
        PlaceDTO(
            placeId: id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            address: address
        )
    }

    private func makeBounds() -> BoundingBox {
        BoundingBox(
            minLatitude: -90,
            maxLatitude: 90,
            minLongitude: -180,
            maxLongitude: 180
        )
    }

    // MARK: - Tests

    @Test("create가 성공하면, fetchRecent로 저장 결과를 확인할 수 있다")
    func create() async throws {
        let container = try makeInMemoryContainer()
        let storage = makeStorage()
        await storage.configure(container: container)

        let dto = makeCreateDTO(content: "hello")
        try await storage.create(for: dto)

        let results = try await storage.fetchRecent(page: 0, pageSize: 10)
        #expect(results.count == 1)
        #expect(results.first?.content == "hello")
    }

    @Test("특정 place가 있는 데이터만 fetchByPlace로 확인할 수 있다")
    func fetchByPlace() async throws {
        let container = try makeInMemoryContainer()
        let storage = makeStorage()
        await storage.configure(container: container)

        let placeA = makePlaceDTO(id: "A")
        let placeB = makePlaceDTO(id: "B")

        try await storage.create(for: makeCreateDTO(content: "pA-1", place: placeA))
        try await storage.create(for: makeCreateDTO(content: "pB-1", place: placeB))
        try await storage.create(for: makeCreateDTO(content: "no-place", place: nil))
        try await storage.create(for: makeCreateDTO(content: "pA-2", place: placeA))

        let resultsA = try await storage.fetchByPlace(at: PlaceID(value: "A"), limit: nil)
        #expect(resultsA.count == 2)
        #expect(resultsA.allSatisfy { $0.place?.placeId == "A" })

        let resultsB = try await storage.fetchByPlace(at: PlaceID(value: "B"), limit: nil)
        #expect(resultsB.count == 1)
        #expect(resultsB.first?.place?.placeId == "B")
    }

    @Test("특정 id delete 시, fetchRecent에서 삭제된 메시지는 조회되지 않는다")
    func delete() async throws {
        let container = try makeInMemoryContainer()
        let storage = makeStorage()
        await storage.configure(container: container)

        try await storage.create(for: makeCreateDTO(content: "m1"))
        try await storage.create(for: makeCreateDTO(content: "m2"))
        try await storage.create(for: makeCreateDTO(content: "m3"))

        let before = try await storage.fetchRecent(page: 0, pageSize: 10)

        // 삭제 대상: 최근 2개를 지워보자
        let idsToDelete: Set<MessageID> = Set(before.prefix(2).map { MessageID(value: $0.id) })
        try await storage.delete(messageIDs: idsToDelete)

        let after = try await storage.fetchRecent(page: 0, pageSize: 10)
        #expect(after.count == 1)

        let remainingIDs = Set(after.map { MessageID(value: $0.id) })
        #expect(remainingIDs.isDisjoint(with: idsToDelete))
    }

    @Test("데이터가 존재하는 상태에서 reset 이후에도 create/save가 정상 동작한다")
    func reset() async throws {
        let container = try makeInMemoryContainer()
        let storage = makeStorage()
        await storage.configure(container: container)

        try await storage.create(for: makeCreateDTO(content: "before-reset"))
        #expect((try await storage.fetchRecent(page: 0, pageSize: 10)).count == 1)

        try await storage.reset()
        #expect((try await storage.fetchRecent(page: 0, pageSize: 10)).isEmpty)

        // reset 이후에도 다시 기록 가능해야 함
        try await storage.create(for: makeCreateDTO(content: "after-reset"))
        let results = try await storage.fetchRecent(page: 0, pageSize: 10)
        #expect(results.count == 1)
        #expect(results.first?.content == "after-reset")
    }

    @Test("여러 좌표 데이터가 있는 상태에서, fetchNearby를 호출하면 bounds 범위 내 distance 오름차순 정렬 결과를 반환한다")
    func fetchNearby() async throws {
        let container = try makeInMemoryContainer()
        let storage = makeStorage()
        await storage.configure(container: container)

        // 기준점
        let origin = Coordinate(latitude: 37.0, longitude: 127.0)
        let bounds = makeBounds()

        // origin에 가까운 순서대로 결과가 나와야 한다
        try await storage.create(for: makeCreateDTO(content: "near", latitude: 37.0001, longitude: 127.0001))
        try await storage.create(for: makeCreateDTO(content: "far", latitude: 38.0, longitude: 128.0))
        try await storage.create(for: makeCreateDTO(content: "mid", latitude: 37.1, longitude: 127.1))

        let results = try await storage.fetchNearby(at: origin, bounds: bounds, limit: nil)
        let contents = results.map(\.content)

        #expect(contents.first == "near")
        #expect(contents.contains("mid"))
        #expect(contents.last == "far")
    }
}
