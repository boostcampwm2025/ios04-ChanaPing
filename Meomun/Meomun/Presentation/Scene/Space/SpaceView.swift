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
        }
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
                .foregroundStyle(Color.meomunPrimaryColor)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.meomunBackgroundColor.opacity(0.8))
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
