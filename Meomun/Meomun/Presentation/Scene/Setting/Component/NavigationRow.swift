//
//  NavigationRow.swift
//  Meomun
//
//  Created by hoon on 1/28/26.
//

import SwiftUI

struct NavigationRow<Destination: View>: View {
    let title: String
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
        } label: {
            Text(title)
        }
    }
}
