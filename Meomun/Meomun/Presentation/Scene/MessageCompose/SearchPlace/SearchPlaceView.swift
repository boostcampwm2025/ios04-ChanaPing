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
}

struct SearchPlaceView: View {
    @State private var query: String = ""
    @FocusState private var isFocused: Bool

    let onSelect: (String) -> Void
    let onDismiss: () -> Void

    init(
        onSelect: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.onSelect = onSelect
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

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

extension SearchPlaceView {
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
            TextField(Constants.searchTextFieldPlaceholder, text: $query)
                .focused($isFocused)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.meomunPrimaryColor)
                .submitLabel(.search)
                .onSubmit {
                    // TODO: 실제 검색 API 호출
                }
                .onAppear {
                    UITextField.appearance().clearButtonMode = .whileEditing
                }
        }
        .padding(.horizontal)
    }

    private var filtered: [String] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        return [query]  // TODO: 실제 검색 결과 리턴
    }

    var searchResultList: some View {
        Group {
            if filtered.isEmpty {
                // 검색 결과 없을 때
                emptyView

                Spacer()
            } else {
                // 검색 결과 있을 때
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(filtered, id: \.self) { place in
                            Button {
                                onSelect(place)
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(place)
                                        .font(.system(size: 14, weight: .medium))
                                    Spacer()
                                }
                                .foregroundStyle(Color.meomunPrimaryColor)
                                .padding(.vertical, 10)
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

    var emptyView: some View {
        Text(Constants.searchEmptyText)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Color.meomunSecondaryColor)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
    }
}

#Preview {
    NavigationStack {
        SearchPlaceView { selected in
            print(selected)
        } onDismiss: {
            print("dismiss")
        }

    }
}
