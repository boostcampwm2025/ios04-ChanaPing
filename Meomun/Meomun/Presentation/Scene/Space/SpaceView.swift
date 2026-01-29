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
    @Environment(\.dismiss) private var dismiss

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
                TapGesture().onEnded { send(.selectMessage(nil)) }
            )
            .highPriorityGesture(
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
        .overlay(alignment: .bottom) {
            selectionBar
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: store.state.selectedMessageID)
        .allowsHitTesting(store.state.deleteStatus == .idle)
        .navigationBarBackButtonHidden()
        .toolbar { toolbarContent }
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

// MARK: - Actions

private extension SpaceView {
    func send(_ intent: SpaceStore.Intent) {
        Task { await store.send(intent: intent) }
    }
}

// MARK: Subviews

extension SpaceView {
    @ViewBuilder
    var selectionBar: some View {
        Group {
            if store.state.selectedMessageID != nil {
                HStack {
                    Button { send(.selectMessage(nil)) } label: {
                        Text("취소")
                            .font(.headline)
                            .foregroundStyle(Color.mmPrimary)
                            .padding(.horizontal, 16)
                    }

                    Spacer()

                    if let messageID = store.state.selectedMessageID {
                        Button { send(.requestDeleteMessage(messageID)) } label: {
                            Text("삭제")
                                .font(.headline)
                                .foregroundStyle(Color.red)
                                .padding(.horizontal, 24)
                        }
                    }
                }
            } else {
                Text("\(store.state.messages.count)개의 추억이 떠다니고 있어요")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.mmPrimary)
                    .frame(maxWidth: .infinity)
            }
        }
        .floatingContainer()
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

// MARK: Toolbar / Actions
private extension SpaceView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: .topBarLeading) {
                backToolbarButton
            }
            .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarLeading) {
                backToolbarButton
            }
        }

        ToolbarItem(placement: .principal) { placeTitle }
    }

    var backToolbarButton: some View {
        BackButton { dismiss() }
    }

    var placeTitle: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.and.ellipse")
                .font(.caption)
                .foregroundStyle(Color.tabActive)

            Text(place.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.mmPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.mmBackground.opacity(0.8))
        )
        .shadow(color: .black.opacity(0.15), radius: 6, y: 4)
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
