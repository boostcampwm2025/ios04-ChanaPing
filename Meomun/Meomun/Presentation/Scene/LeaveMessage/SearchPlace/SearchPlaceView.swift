//
//  SearchPlaceView.swift
//  Meomun
//
//  Created by MinwooJe on 1/7/26.
//

import SwiftUI

fileprivate enum Constants {
    static let navigationTitle = "장소 검색"
    static let searchTextFieldPlaceholder = "지금 어디에 있나요?"
}

struct SearchPlaceView: View {
    @State var text: String = ""

    var body: some View {
        VStack {
            searchBar

            searchResultList
        }
        .navigationTitle(Constants.navigationTitle)
    }
}

extension SearchPlaceView {
    var searchBar: some View {
        PlaceSearchContainerView {
            TextField(Constants.searchTextFieldPlaceholder, text: $text)
        }
        .padding(.horizontal)
    }

    var searchResultList: some View {
        List {
            Text("장소")
        }
        .listStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        LeaveMessageView()
    }
}
