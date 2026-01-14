//
//  SearchPlaceView.swift
//  Meomun
//
//  Created by MinwooJe on 1/7/26.
//

import SwiftUI

fileprivate enum Constants {
    static let title = "장소 검색"
    static let searchTextFieldPlaceholder = "지금 어디에 있나요?"
    static let searchEmptyText = "검색 결과가 없어요."
    static let emptyText = "검색어를 입력해 주세요."
}

struct PlaceSearchOverlayView: View {
    @FocusState private var isFocused: Bool
    @StateObject private var store: PlaceSearchStore

    init(store: PlaceSearchStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { Task { await store.send(intent: .dismiss) } }

            VStack {
                header
                searchBar
                searchResultList
            }
            .padding(28)
            .frame(width: 320, height: 400)
            .background(Color.white)
            .cornerRadius(25)
            .shadow(radius: 8)

            .onTapGesture {
                isFocused = false
            }
            .onAppear {
                DispatchQueue.main.async { isFocused = true }
            }
        }
    }
}

extension PlaceSearchOverlayView {
    var header: some View {
        HStack {
            Spacer()
            Text(Constants.title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.meomunPrimaryColor)
            Spacer()
        }
    }

    var searchBar: some View {
        PlaceSearchContainerView {
            TextField(Constants.searchTextFieldPlaceholder, text: Binding(
                get: { store.state.query },
                set: { newValue in
                    Task { await store.send(intent: .queryChanged(newValue)) }
                }
            ))
                .focused($isFocused)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.meomunPrimaryColor)
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
                emptyView(text: Constants.emptyText)
                Spacer()

            case .loading:
                ProgressView()
                Spacer()

            case .empty:
                emptyView(text: Constants.searchEmptyText)
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
                                        Text(place.address ?? "")
                                            .font(.system(size: 11, weight: .thin))
                                            .foregroundStyle(Color.gray)
                                    }
                                    Spacer()
                                }
                                .foregroundStyle(Color.meomunPrimaryColor)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 12)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
            .foregroundStyle(Color.meomunSecondaryColor)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
    }
}

#Preview {
    NavigationStack {
        PlaceSearchOverlayView(
            store: PlaceSearchStore(
                searchPlaces: SearchNearbyPlaceUseCase(
                    placeRepository: NaverPlaceSearchRepositoryImpl(
                        network: NetworkClientImpl()
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
