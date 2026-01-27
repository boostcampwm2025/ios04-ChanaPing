//
//  AlertFactory.swift
//  Meomun
//
//  Created by MinwooJe on 1/27/26.
//

import Foundation

enum AlertFactory {
    static func deleteMessage(
        count: Int,
        onConfirm: @escaping () -> Void
    ) -> AlertModel {
        AlertModel(
            title: "메시지 삭제",
            message: count == 1
                ? "이 메시지를 삭제하시겠습니까?"
                : "\(count)개의 메시지를 삭제하시겠습니까?",
            buttons: [
                AlertButtonConfig(title: "취소", role: .cancel, action: nil),
                AlertButtonConfig(title: "삭제", role: .destructive, action: onConfirm)
            ]
        )
    }
}
