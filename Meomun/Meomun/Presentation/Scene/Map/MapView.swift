//
//  MapView.swift
//  Meomun
//
//  Created by 송지연 on 12/22/25.
//

import SwiftUI

struct MapView: View {
    @State private var showAddMessage = false

    var body: some View {
        ZStack {
            MapViewWrapper()
                .ignoresSafeArea()

            VStack {
                FloatingNavigationBar(
                    title: "머문",
                    onTapSearch: {}
                )

                Spacer()
                HStack {
                    Spacer()
                    WriteButton {
                        showAddMessage = true
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 96)
        }
        .sheet(isPresented: $showAddMessage) {
            AddMessageView()
        }
    }
}

#Preview {
    MapView()
}
