//
//  MapStoreTests.swift
//  MeomunTests
//
//  Created by MinwooJe on 1/20/26.
//

import Testing
import Foundation
@testable import Meomun


// MARK: - MapStoreTests

@Suite("MapStore 테스트: 카메라 위치 기준으로 메시지 불러오기")
struct MapStoreTests {

    /// 동일 설정으로 모든 테스트에서 공유하는 TestDouble
    private static let stubNetworkMonitor: NetworkMonitoring = StubNetworkMonitor()
    private static let stubBoundingBox = BoundingBox(minLatitude: 0, maxLatitude: 0, minLongitude: 0, maxLongitude: 0)
    private static let stubMapCameraSnapshot = MapCameraSnapshot(coordinate: .init(latitude: 0, longitude: 0))

    // MARK: - Scenario 1: 앱 실행 후 지도 화면 진입

    @Suite("시나리오 1: 지도 화면 진입 시 메시지 표시")
    struct OnAppearTests {
        let stubbedCoordinate = DummyMessageFactory.seoulCityHallCoordinate

        @Test("지도 화면 진입 시 카메라 좌표가 사용자의 현재 위치로 정상적으로 설정 되는지")
        func setCameraCoordinateOnAppear() async throws {
            // Arrange
            let expectedCoordinate = stubbedCoordinate
            let expectedResult = expectedCoordinate
            let stubUseCase = StubGetNearbyMessagesUseCase(stubbedMessages: [])
            let sut = MapStore(getNearbyMessagesUseCase: stubUseCase, networkMonitor: MapStoreTests.stubNetworkMonitor)

            // Act
            await sut.send(intent: .onAppear(expectedCoordinate))

            // Assert
            let actualResult = sut.state.cameraCoordinate

            #expect(actualResult == expectedResult)
        }
    }

    // MARK: - Scenario 2: 카메라 드래그로 이동

    @Suite("시나리오 2: 지도 드래그 시 메시지 표시")
    struct CameraDidIdleTests {
        let stubbedCoordinate = DummyMessageFactory.seoulCityHallCoordinate
        let testCoordinate = DummyMessageFactory.busanHaeundaeCoordinate

        @Test("지도를 드래그하여 카메라 이동 시 새 위치의 메시지가 정상적으로 불러와지는지")
        func fetchMessagesAfterCameraDrag() async throws {
            // Arrange
            let expectedResult = DummyMessageFactory.makeMessages(count: 3, at: stubbedCoordinate)
            let stubUseCase = StubGetNearbyMessagesUseCase(stubbedMessages: expectedResult)
            let sut = MapStore(getNearbyMessagesUseCase: stubUseCase, networkMonitor: MapStoreTests.stubNetworkMonitor)
            let newCameraPosition = stubbedCoordinate

            // Act
            await sut.send(intent: .cameraDidIdle(newCameraPosition, MapStoreTests.stubBoundingBox, MapStoreTests.stubMapCameraSnapshot))

            // Assert
            let actualResult = sut.state.messages

            #expect(actualResult.map { $0.id } == expectedResult.map { $0.id })
        }

        @Test("지도를 드래그하여 카메라 이동 시 저장된 카메라 좌표가 정상적으로 업데이트 되는지")
        func updateCameraCoordinateImmediately() async throws {
            // Arrange
            let expectedResult = testCoordinate
            let stubUseCase = StubGetNearbyMessagesUseCase(stubbedMessages: [])
            let sut = MapStore(getNearbyMessagesUseCase: stubUseCase, networkMonitor: MapStoreTests.stubNetworkMonitor)
            let movedCoordinate = testCoordinate

            // Act
            await sut.send(intent: .cameraDidIdle(movedCoordinate, MapStoreTests.stubBoundingBox, MapStoreTests.stubMapCameraSnapshot))

            // Assert
            let actualResult = sut.state.cameraCoordinate

            #expect(actualResult == expectedResult)
        }

        @Test("지도를 연속적으로 드래그 시 마지막 위치를 기준으로 메시지를 불러오는지 (debounce 테스트)")
        func debounceMultipleCameraIdleEvents() async throws {
            // Arrange
            let expectedCallCount = 1
            let spyUseCase = SpyGetNearbyMessagesUseCase(stubbedMessages: [])
            let sut = MapStore(getNearbyMessagesUseCase: spyUseCase, networkMonitor: MapStoreTests.stubNetworkMonitor)

            let firstLocation = stubbedCoordinate
            let secondLocation = DummyMessageFactory.gangnamStationCoordinate
            let thirdLocation = testCoordinate

            // Act - 100ms 간격으로 3번 드래그 (debounce 300ms 내)
            // 실제 View에서는 send를 await하지 않고 fire-and-forget으로 호출
            Task { await sut.send(intent: .cameraDidIdle(firstLocation, MapStoreTests.stubBoundingBox, MapStoreTests.stubMapCameraSnapshot)) }
            try await Task.sleep(nanoseconds: 100_000_000)
            Task { await sut.send(intent: .cameraDidIdle(secondLocation, MapStoreTests.stubBoundingBox, MapStoreTests.stubMapCameraSnapshot)) }
            try await Task.sleep(nanoseconds: 100_000_000)
            Task { await sut.send(intent: .cameraDidIdle(thirdLocation, MapStoreTests.stubBoundingBox, MapStoreTests.stubMapCameraSnapshot)) }

            // debounce 완료 대기 (300ms + 여유)
            try await Task.sleep(nanoseconds: 500_000_000)

            // Assert - 마지막 위치로만 호출
            let actualCallCount = spyUseCase.executeCallCount

            #expect(actualCallCount == expectedCallCount)
            #expect(spyUseCase.lastCalledLocation == thirdLocation)
        }
    }

    // MARK: - Scenario 3: 현재 위치 버튼 탭

    @Suite("시나리오 3: 현재 위치 버튼 탭")
    struct CurrentLocationButtonTests {
        let stubbedCoordinate = DummyMessageFactory.seoulCityHallCoordinate

        @Test("현위치 버튼 탭 시 해당 위치의 메시지를 정상적으로 불러오는지")
        func fetchMessagesWhenCameraChangedByLocation() async throws {
            // Arrange
            let expectedResult = DummyMessageFactory.makeMessages(count: 2, at: stubbedCoordinate)
            let spyUseCase = StubGetNearbyMessagesUseCase(stubbedMessages: expectedResult)
            let sut = MapStore(getNearbyMessagesUseCase: spyUseCase, networkMonitor: MapStoreTests.stubNetworkMonitor)
            let movedCoordinate = stubbedCoordinate

            // Act
            await sut.send(intent: .cameraChangedByLocation(movedCoordinate, MapStoreTests.stubBoundingBox, MapStoreTests.stubMapCameraSnapshot))
            let actualResult = sut.state.messages

            // Assert
            #expect(actualResult.map { $0.id } == expectedResult.map { $0.id } )
        }

        @Test("현위치 버튼 탭 시 저장된 카메라 좌표가 정상적으로 업데이트 되는지")
        func updateCameraCoordinateImmediately() async throws {
            // Arrange
            let expectedResult = stubbedCoordinate
            let stubUseCase = StubGetNearbyMessagesUseCase(stubbedMessages: [])
            let sut = MapStore(getNearbyMessagesUseCase: stubUseCase, networkMonitor: MapStoreTests.stubNetworkMonitor)

            // Act
            await sut.send(intent: .cameraDidIdle(expectedResult, MapStoreTests.stubBoundingBox, MapStoreTests.stubMapCameraSnapshot))

            // Assert
            let actualResult = sut.state.cameraCoordinate

            #expect(actualResult == expectedResult)
        }
    }

    // MARK: - Scenario 4: 사용자 이동 시 메시지 표시

    @Suite("시나리오 4: 사용자 이동 시 메시지 표시")
    struct UserMovementTests {
        let stubbedCoordinate = DummyMessageFactory.gangnamStationCoordinate

        @Test("사용자 이동으로 카메라 변경 시 새 위치의 메시지를 정상적으로 불러오는지")
        func fetchMessagesOnUserMovement() async throws {
            // Arrange
            let expectedResult = DummyMessageFactory.makeMessages(count: 4, at: stubbedCoordinate)
            let stubUseCase = StubGetNearbyMessagesUseCase(stubbedMessages: expectedResult)
            let sut = MapStore(getNearbyMessagesUseCase: stubUseCase, networkMonitor: MapStoreTests.stubNetworkMonitor)
            let movedCoordinate = stubbedCoordinate

            // Act
            await sut.send(intent: .cameraChangedByLocation(movedCoordinate, MapStoreTests.stubBoundingBox, MapStoreTests.stubMapCameraSnapshot))

            // Assert
            let actualResult = sut.state.messages


            #expect(actualResult.map { $0.id } == expectedResult.map { $0.id })
        }
    }
}
