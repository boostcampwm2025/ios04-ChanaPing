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

    @State private var isSpaceReady: Bool = false
    @State private var showPortal: Bool = true

    @State private var appearOpacity: Double = 0

    private let place: Place
    private let onNavigate: (Coordinate, Place) -> Void

    init(
        store: SpaceStore,
        place: Place,
        onNavigate: @escaping (Coordinate, Place) -> Void
    ) {
        _store = StateObject(wrappedValue: store)
        _spaceController = State(
            wrappedValue: SpaceController()
        )
        self.place = place
        self.onNavigate = onNavigate
    }

    var body: some View {
        ZStack {
            RealityView { content in
                // 가상 카메라 모드 설정 (AR이 아닌 3D 공간)
                content.camera = .virtual
                spaceController.configureSpace(content: content) {
                    isSpaceReady = true
                }
            }
            .opacity(isSpaceReady ? (showPortal ? 0.25 : 1.0) : 0.0)
            .animation(.easeInOut(duration: 0.35), value: isSpaceReady)
            .animation(.easeInOut(duration: 0.22), value: showPortal)
            .allowsHitTesting(isSpaceReady)
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

                    WriteButton {
                        if let coordinate = locationProvider.current {
                            onNavigate(coordinate, store.place)
                        }
                    }
                    .opacity(!showPortal ? 1 : 0)
                }
                .padding(.bottom, 96)
            }

            if store.state.deleteStatus != .idle {
                MMLoadingOverlayView(
                    status: store.state.deleteStatus,
                    message: deleteStatusMessage
                )
                .opacity(!showPortal ? 1 : 0)
            }

            if showPortal {
                PortalLoadingOverlay(
                    title: place.name,
                    isReady: isSpaceReady
                ) {
                    showPortal = false
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.22), value: showPortal)
                .zIndex(999)
            }
        }
        .mmAlert(
            $store.state.deleteAlert,
            title: { $0.title },
            message: { $0.message },
            buttons: { $0.buttons }
        )
        .overlay(alignment: .bottom) {
            selectionBar
                .opacity(!showPortal ? 1 : 0)
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: store.state.selectedMessageID)
        .allowsHitTesting(store.state.deleteStatus == .idle)
        .overlay(alignment: .top) {
            SpaceTopBar(
                title: place.name,
                onBack: { dismissWithFade() }
            )
            .padding(.top, 12)
            .opacity(!showPortal ? 1 : 0)
        }
        .task {
            isSpaceReady = false
            showPortal = true
            await store.send(intent: .onAppear(placeID: place.id))
        }
        .onChange(of: store.state.messages.map(\.id)) {
            spaceController.sync(messages: store.state.messages)
        }
        .onChange(of: store.state.domeEnvironment) { _, newValue in
            guard let newValue else { return }
            spaceController.update(domeEnvironment: newValue)
        }
        .opacity(appearOpacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.25)) {
                appearOpacity = 1
            }
        }
    }

    func dismissWithFade() {
        Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.25)) {
                appearOpacity = 0
            }
            try? await Task.sleep(nanoseconds: 250_000_000)
            dismiss()
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

// MARK: - Subviews

extension SpaceView {
    @ViewBuilder
    var selectionBar: some View {
        Group {
            if store.state.selectedMessageID != nil {
                HStack {
                    Button { send(.selectMessage(nil)) } label: {
                        Text("취소")
                            .font(.headline)
                            .foregroundStyle(Color.mmTextBrand)
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
                    .foregroundStyle(Color.mmTextBrand)
                    .frame(maxWidth: .infinity)
            }
        }
        .mmFloatingContainer(color: Color.mmBackground, opacity: 0.8)
    }
}

// MARK: - Computed property

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
    let storage = MessageInMemoryStorage.shared
    NavigationStack {
        SpaceView(
            store: .init(
                fetchPlaceMessagesUseCase: FetchPlaceMessagesUseCaseImpl(
                    messageRepository: MessageRepositoryImpl(storage: storage)
                ),
                deleteMessagesUseCase: DeleteMessagesUseCaseImpl(
                    messageRepository: MessageRepositoryImpl(storage: storage)
                ),
                place: .init(
                    id: .init(value: .init()),
                    name: "광화문",
                    coordinate: .init(latitude: 0, longitude: 0)
                )
            ),
            place: .init(
                id: .init(value: .init()),
                name: "광화문",
                coordinate: .init(latitude: 0, longitude: 0)
            ),
            onNavigate: { _, _ in }
        )
    }
}
