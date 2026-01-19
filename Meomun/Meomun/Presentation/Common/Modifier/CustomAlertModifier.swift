//
//  CustomAlertModifier.swift
//  Meomun
//
//  Created by Hayeon Park on 1/20/26.
//

import SwiftUI

struct AlertButtonConfig {
    enum Role {
        case normal
        case cancel
        case destructive
    }

    let title: String
    let role: Role
    let action: (() -> Void)?

    static let confirm = AlertButtonConfig(
        title: "확인",
        role: .cancel,
        action: nil
    )
}

struct CustomAlertModifier<AlertModel>: ViewModifier {
    @Binding var alert: AlertModel?

    let title: (AlertModel) -> String
    let message: (AlertModel) -> String
    let buttons: (AlertModel) -> [AlertButtonConfig]

    func body(content: Content) -> some View {
        let isPresented = Binding<Bool>(
            get: { alert != nil },
            set: { newValue in
                if !newValue { alert = nil }
            }
        )

        content.alert(
            alert.map(title) ?? "",
            isPresented: isPresented,
            presenting: alert
        ) { alert in
            let configs = Array(buttons(alert))

            if configs.isEmpty {
                Button("확인", role: .cancel) {}
            } else {
                ForEach(Array(configs.enumerated()), id: \.offset) { _, config in
                    makeButton(config)
                }
            }
        } message: { alert in
            Text(message(alert))
        }
    }

    @ViewBuilder
    private func makeButton(_ config: AlertButtonConfig) -> some View {
        let action: () -> Void = {
            alert = nil

            Task { @MainActor in
                config.action?()
            }
        }

        switch config.role {
        case .cancel:
            Button(config.title, role: .cancel, action: action)
        case .destructive:
            Button(config.title, role: .destructive, action: action)
        case .normal:
            Button(config.title, action: action)
        }
    }
}

extension View {
    func customAlert<AlertModel>(
        _ alert: Binding<AlertModel?>,
        title: @escaping (AlertModel) -> String,
        message: @escaping (AlertModel) -> String,
        buttons: @escaping (AlertModel) -> [AlertButtonConfig] = { _ in [] }
    ) -> some View {
        modifier(
            CustomAlertModifier(
                alert: alert,
                title: title,
                message: message,
                buttons: buttons
            )
        )
    }
}
