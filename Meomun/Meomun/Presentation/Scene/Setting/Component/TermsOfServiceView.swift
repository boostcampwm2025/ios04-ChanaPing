//
//  TermsOfServiceView.swift
//  Meomun
//
//  Created by hoon on 2/3/26.
//

import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        MarkdownDocumentView(
            title: "이용약관",
            resourceName: "TermsOfService"
        )
    }
}
