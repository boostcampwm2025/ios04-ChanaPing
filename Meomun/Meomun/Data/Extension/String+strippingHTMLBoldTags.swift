//
//  String+strippingHTMLBoldTags.swift
//  Meomun
//
//  Created by 지연 on 1/14/26.
//

import Foundation

extension String {
    func strippingHTMLBoldTags() -> String {
        self.replacingOccurrences(of: "<b>", with: "")
            .replacingOccurrences(of: "</b>", with: "")
    }
}
