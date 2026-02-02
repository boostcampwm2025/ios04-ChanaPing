//
//  SearchPlaceView.swift
//  Meomun
//
//  Created by MinwooJe on 1/7/26.
//

import SwiftUI

fileprivate enum Defaults {
    static let title = "장소 검색"
    static let searchTextFieldPlaceholder = "지금 어디에 있나요?"
    static let searchEmptyText = "검색 결과가 없어요."
    static let emptyText = "검색어를 입력해 주세요."
}

struct PlaceSearchOverlayView: View {
    @FocusState private var isFocused: Bool
    @StateObject private var store: PlaceSearchStore

    @State private var isPresented = false

    private let title: String
    private let placeholder: String

    init(store: PlaceSearchStore,
         title: String = Defaults.title,
         placeholder: String = Defaults.searchTextFieldPlaceholder) {
        _store = StateObject(wrappedValue: store)
        self.title = title
        self.placeholder = placeholder
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    if isFocused {
                        isFocused = false
                    } else {
                        Task { await store.send(intent: .dismiss) }
                    }
                }

            if isPresented {
                VStack {
                    header
                    searchBar
                    searchResultList
                }
                .padding(28)
                .frame(width: 320, height: 400)
                .background(Color.mmContainerBackground)
                .cornerRadius(25)
                .shadow(radius: 8)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .onTapGesture {
                    isFocused = false
                }
            }
        }
        .onAppear {
            isFocused = true
            withAnimation(.easeInOut(duration: 0.3)) {
                isPresented = true
            }
        }
        .onDisappear { isPresented = false }
    }
}

extension PlaceSearchOverlayView {
    var header: some View {
        ZStack {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.mmTextBrand)

            HStack {
                Spacer()

                Button {
                    Task { await store.send(intent: .dismiss) }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.mmSecondary)
                        .padding(10)
                        .contentShape(Rectangle())
                }
            }
        }
    }

    var searchBar: some View {
        PlaceSearchContainerView {
            TextField(placeholder, text: Binding(
                get: { store.state.query },
                set: { newValue in
                    Task { await store.send(intent: .queryChanged(newValue)) }
                }
            ))
                .focused($isFocused)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.mmTextBrand)
                .submitLabel(.search)
                .onSubmit {
                    Task { await store.send(intent: .submit) }
                }
                .onAppear {
                    UITextField.appearance().clearButtonMode = .whileEditing
                }
        }
        .padding(.horizontal)
    }

    var searchResultList: some View {
        Group {
            switch store.state.phase {
            case .idle:
                emptyView(text: Defaults.emptyText)
                Spacer()

            case .loading:
                ProgressView()
                Spacer()

            case .empty:
                emptyView(text: Defaults.searchEmptyText)
                Spacer()

            case .failed(let message):
                emptyView(text: message)
                Spacer()

            case .loaded(let results):
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(results, id: \.self) { place in
                            Button {
                                Task { await store.send(intent: .tapResult(place)) }
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.system(size: 14, weight: .semibold))
                                        .padding(.trailing, 1)

                                    VStack(alignment: .leading) {
                                        Text(place.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .padding(.bottom, 1)
                                        Text(place.address)
                                            .font(.system(size: 11, weight: .thin))
                                            .foregroundStyle(Color.gray)
                                    }
                                    Spacer()
                                }
                                .onAppear {
                                    if place == results.last {
                                        Task { await store.send(intent: .scrollReachedBottom) }
                                    }
                                }
                                .foregroundStyle(Color.mmTextBrand)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    func emptyView(text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Color.mmSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
    }
}

#Preview {
    NavigationStack {
        PlaceSearchOverlayView(
            store: PlaceSearchStore(
                searchPlaces: SearchNearbyPlaceUseCaseImpl(
                    placeRepository: NaverPlaceSearchRepositoryImpl(
                        remote: SupabaseServiceImpl(network: NetworkClientImpl())
                    )
                ),
                userLocation: .init(
                    latitude: 37.5665,
                    longitude: 126.9780
                ),
                onSelect: { selected in
                    print("selected: \(selected)")
                },
                onDismiss: {
                    print("tap dismiss")
                }
            )
        )
    }
}
