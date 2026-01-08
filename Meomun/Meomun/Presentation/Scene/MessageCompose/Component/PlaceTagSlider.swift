//
//  PlaceTagSlider.swift
//  Meomun
//
//  Created by Hayeon Park on 1/7/26.
//

import SwiftUI

struct PlaceTagSlider: View {
    let places: [String]
    var onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(places, id: \.self) { tag in
                    PlaceTagButton(title: tag) {
                        onSelect(tag)
                    }
                }
            }
        }
        .frame(maxHeight: 40)
    }
}

#Preview {
    PlaceTagSlider(places: ["스타벅스 파주가람점", "ONUTE", "콰이어트라이트", "메가MGC커피 파주별하람마을점"], onSelect: {_ in })
}
