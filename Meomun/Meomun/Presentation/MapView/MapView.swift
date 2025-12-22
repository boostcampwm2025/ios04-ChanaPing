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
            // TODO: - 지도뷰

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    WriteButton {
                        showAddMessage = true
                    }
                }
            }
            .padding(.bottom, 30)
            .padding(.trailing, 30)
        }
        .sheet(isPresented: $showAddMessage) {
            AddMessageView()
        }
    }
}

#Preview {
    MapView()
}
