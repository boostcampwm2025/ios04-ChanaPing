//
//  SpaceView.swift
//  Meomun
//
//  Created by MinwooJe on 1/6/26.
//

import RealityKit
import SwiftUI

struct SpaceView: View {
    @EnvironmentObject private var locationProvider: LocationProvider
    @StateObject private var store: SpaceStore
    @State private var spaceController: SpaceController

    private let place: Place
    private let onNavigate: (Coordinate, Place) -> Void

    init(
        store: SpaceStore,
        domeEnvironment: DomeEnvironment,
        place: Place,
        onNavigate: @escaping (Coordinate, Place) -> Void
    ) {
        _store = StateObject(wrappedValue: store)
        _spaceController = State(
            wrappedValue: SpaceController(domeEnvironment: domeEnvironment)
        )
        self.place = place
        self.onNavigate = onNavigate
    }

    var body: some View {
        ZStack {
            RealityView { content in
                // 가상 카메라 모드 설정 (AR이 아닌 3D 공간)
                content.camera = .virtual
                spaceController.configureSpace(content: content)
            }
            .gesture(
                DragGesture()
                    .onChanged { spaceController.handleDrag($0.translation) }
                    .onEnded { _ in spaceController.endDrag()}
            )
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        handleBubbleTap(entity: value.entity)
                    }
            )
            .ignoresSafeArea()

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    WriteButton {   // TODO: - 위치 조정 필요
                        if let coordinate = locationProvider.current {
                            onNavigate(coordinate, store.place)
                        }
                    }
                }
                .padding(.bottom, 96)
            }

            if store.state.deleteStatus != .idle {
                LoadingOverlayView(
                    status: store.state.deleteStatus,
                    message: deleteStatusMessage
                )
            }
        }
        .customAlert(
            $store.state.deleteAlert,
            title: { $0.title },
            message: { $0.message },
            buttons: { $0.buttons }
        )
        .confirmationDialog(
            "메시지 관리",
            isPresented: Binding(
                get: {
                    store.state.selectedMessageID != nil
                },
                set: { isPresented in
                    if !isPresented {
                        Task {
                            await store.send(intent: .selectMessage(nil))
                        }
                    }
                }
            ),
            presenting: store.state.selectedMessageID
        ) { messageID in
            Button("삭제", role: .destructive) {
                Task {
                    await store.send(intent: .requestDeleteMessage(messageID))
                }
            }
        }
        .allowsHitTesting(store.state.deleteStatus == .idle)
        .task {
            await store.send(intent: .onAppear(placeID: place.id))
        }
        .onChange(of: store.state.messages.map(\.id)) {
            spaceController.sync(messages: store.state.messages)
        }
    }
}

// MARK: - Handle Gesture

extension SpaceView {
    private func handleBubbleTap(entity: Entity?) {
        guard let entity = entity,
              let component = entity.components[MessageBubbleIDComponent.self] else {
            return
        }

        Task {
            await store.send(intent: .selectMessage(component.messageID))
        }
    }
}

// MARK: Computed property

extension SpaceView {
    private var deleteStatusMessage: String {
        switch store.state.deleteStatus {
        case .loading: return "메시지를 삭제하고 있어요"
        case .success: return "메시지를 삭제했어요"
        case .fail: return "메시지 삭제에 실패했어요"
        case .idle: return ""
        }
    }
}

#Preview {
    NavigationStack {
        SpaceView(
            store: .init(
                fetchPlaceMessagesUseCase: FetchPlaceMessagesUseCaseImpl(
                    messageRepository: MessageRepositoryImpl()
                ),
                deleteMessagesUseCase: DeleteMessagesUseCaseImpl(
                    messageRepository: MessageRepositoryImpl()
                ),
                place: .init(
                    id: .init(value: .init()),
                    name: "광화문",
                    coordinate: .init(latitude: 0, longitude: 0)
                )
            ),
            domeEnvironment: .init(dayPart: .afternoon),
            place: .init(
                id: .init(value: .init()),
                name: "광화문",
                coordinate: .init(latitude: 0, longitude: 0)
            ),
            onNavigate: { _, _ in }
        )
    }
}
