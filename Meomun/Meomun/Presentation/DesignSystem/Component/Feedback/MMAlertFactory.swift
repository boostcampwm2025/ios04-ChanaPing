//
//  MMAlertFactory.swift
//  Meomun
//
//  Created by MinwooJe on 1/27/26.
//

import Foundation

enum MMAlertFactory {
    static func deleteMessage(
        count: Int,
        onConfirm: @escaping () -> Void
    ) -> MMAlertModel {
        MMAlertModel(
            title: "메시지 삭제",
            message: count == 1
                ? "이 메시지를 삭제하시겠습니까?"
                : "\(count)개의 메시지를 삭제하시겠습니까?",
            buttons: [
                MMAlertButtonConfig(title: "취소", role: .cancel, action: nil),
                MMAlertButtonConfig(title: "삭제", role: .destructive, action: onConfirm)
            ]
        )
    }

    static func resetAllData(
        onCancel: @escaping () -> Void,
        onReset: @escaping () -> Void
    ) -> MMAlertModel {
        MMAlertModel(
            title: "앱 데이터를 초기화할까요?",
            message: "앱 데이터 초기화 시 모든 로컬 데이터가 삭제되며, 이 작업은 되돌릴 수 없습니다.",
            buttons: [
                MMAlertButtonConfig(title: "취소", role: .cancel, action: onCancel),
                MMAlertButtonConfig(title: "초기화", role: .destructive, action: onReset)
            ]
        )
    }
}
