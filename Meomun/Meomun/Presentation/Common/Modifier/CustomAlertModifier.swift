//
//  CustomAlertModifier.swift
//  Meomun
//
//  Created by Hayeon Park on 1/20/26.
//

import SwiftUI

struct CustomAlertModifier<AlertModel>: ViewModifier {
    let alert: AlertModel?
    let title: (AlertModel) -> String
    let message: (AlertModel) -> String
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        let isPresented = Binding<Bool>(
            get: { alert != nil },
            set: { newValue in
                if !newValue { onDismiss() }
            }
        )

        content.alert(
            alert.map(title) ?? "",
            isPresented: isPresented,
            presenting: alert
        ) { _ in
            Button("확인", role: .cancel) { onDismiss() }
        } message: { alert in
            Text(message(alert))
        }
    }
}

extension View {
    func customAlert<AlertModel>(
        _ alert: AlertModel?,
        title: @escaping (AlertModel) -> String,
        message: @escaping (AlertModel) -> String,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(
            CustomAlertModifier(
                alert: alert,
                title: title,
                message: message,
                onDismiss: onDismiss
            )
        )
    }
}
