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

    @State private var path = NavigationPath()

    init(
        store: SpaceStore
    ) {
        _store = StateObject(wrappedValue: store)
        _spaceController = State(
            wrappedValue: SpaceController()
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.white.ignoresSafeArea()

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
                        .onChanged {
                            if store.state.isGyroEnabled {
                                send(.setGyroEnabled(false))
                            }
                            spaceController.handleDrag($0.translation)
                        }
                        .onEnded { _ in
                            spaceController.endDrag()
                        }
                )
                .gesture(
                    TapGesture().onEnded {
                        if store.state.isGyroEnabled {
                            send(.setGyroEnabled(false))
                        }
                        send(.selectMessage(nil))
                    }
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

                    HStack(alignment: .center) {
                        gyroToggleButton

                        Spacer()

                        WriteButton(mode: .white) {
                            if let coordinate = locationProvider.current {
                                path.append(
                                    SpaceDestination.composer(
                                        location: coordinate,
                                        place: store.place
                                    )
                                )
                            }
                        }
                    }
                    .opacity(!showPortal ? 1 : 0)
                    .allowsHitTesting(!showPortal && isSpaceReady)
                    .padding(.bottom, MMLayout.tabBarBottomOffset)
                    .padding(.horizontal, MMSpacing.floatingHorizontalPadding)
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
                        title: store.place.name,
                        isReady: isSpaceReady
                    ) {
                        showPortal = false
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.22), value: showPortal)
                    .zIndex(999)
                }
            }
            .navigationDestination(for: SpaceDestination.self) { destination in
                switch destination {
                case .composer(let location, let place):
                    let factory: MessageComposerStoreFactory = DIContainer.resolveOrDie()
                    MessageComposerView(
                        store: factory.make(
                            currentLocation: location,
                            currentPlace: place,
                            onClose: { _ in
                                path.removeLast()
                                showPortal = false
                            }
                        )
                    )
                    .navigationBarBackButtonHidden()
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
            .overlay(alignment: .top) {
                SpaceOnboardingTipView()
                    .padding(.top, MMLayout.belowNavigationToolbarOffset)
                    .opacity(!showPortal ? 1 : 0)
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: store.state.selectedMessageID)
            .allowsHitTesting(store.state.deleteStatus == .idle)
            .overlay(alignment: .top) {
                SpaceTopBar(
                    title: store.place.name,
                    onBack: { dismissWithFade() }
                )
                    .padding(.top, 12)
                    .opacity(!showPortal ? 1 : 0)
            }
            .task {
                if !isSpaceReady {
                    showPortal = true
                }
                await store.send(intent: .onAppear(placeID: store.place.id))
                SpaceIntroTip.isReady = true
            }
            .onChange(of: store.state.messages.map(\.id)) {
                spaceController.sync(messages: store.state.messages)
            }
            .onChange(of: store.state.domeEnvironment) { _, newValue in
                guard let newValue else { return }
                spaceController.update(domeEnvironment: newValue)
            }
            .onChange(of: store.state.selectedMessageID) { _, newValue in
                spaceController.selectMessage(newValue)
            }
            .onChange(of: store.state.isGyroEnabled) { _, newValue in
                spaceController.setGyroEnabled(newValue)
            }
            .opacity(appearOpacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.25)) {
                    appearOpacity = 1
                }
            }
        }
    }

    func dismissWithFade() {
        if store.state.isGyroEnabled {
            send(.setGyroEnabled(false))
        }
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
                        Text("선택 취소")
                            .font(.headline)
                            .foregroundStyle(Color.mmTextBrand)
                            .padding(.horizontal, 16)
                    }

                    Spacer()

                    if let messageID = store.state.selectedMessageID {
                        Button { send(.requestDeleteMessage(messageID)) } label: {
                            Text("선택 삭제")
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

    var gyroToggleButton: some View {
        Button {
            send(.setGyroEnabled(!store.state.isGyroEnabled))
        } label: {
            Image(systemName: store.state.isGyroEnabled ? "gyroscope" : "hand.draw")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.mmWriteButton)
                .frame(width: 53, height: 53)
                .background(.mmFloatingBackground.opacity(0.85))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 6, y: 4)
                .accessibilityLabel(store.state.isGyroEnabled ? "자이로스코프 끄기" : "자이로스코프 켜기")
        }
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
            )
        )
    }
}
