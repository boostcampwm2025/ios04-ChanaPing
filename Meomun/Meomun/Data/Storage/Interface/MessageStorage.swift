//
//  MessageStorage.swift
//  Meomun
//
//  Created by MinwooJe on 1/22/26.
//

protocol MessageStorage: Sendable {

    /// 특정 좌표 기준 반경 내의 메시지를 거리순으로 반환합니다.
    /// - Parameters:
    ///   - coordinate: 검색 기준이 되는 중심 좌표
    ///   - limit: 반환할 최대 메시지 개수. nil이면 모든 메시지를 반환합니다.
    func fetchNearby(at location: Coordinate, bounds: BoundingBox, limit: Int?) async throws -> [MessageResponseDTO]

    /// 특정 장소의 메시지를 최신순으로 반환합니다.
    /// - Parameters:
    ///   - placeID: 조회할 장소 ID
    ///   - limit: 반환할 최대 메시지 개수. nil이면 해당 장소의 모든 메시지를 반환합니다.
    func fetchByPlace(at placeID: PlaceID, limit: Int?) async throws -> [MessageResponseDTO]

    /// 최신순으로 정렬된 메시지를 페이지네이션하여 반환합니다.
    /// - Parameters:
    ///   - page: 페이지 번호 (0-based). 0이 첫 번째 페이지입니다.
    ///   - pageSize: 한 페이지에 포함될 메시지 개수
    func fetchRecent(page: Int, pageSize: Int) async throws -> [MessageResponseDTO]

    func create(for message: CreateMessageRequestDTO) async throws

    func update(for message: UpdateMessageRequestDTO) async throws
}
