//
//  MMAlertModifier.swift
//  Meomun
//
//  Created by Hayeon Park on 1/20/26.
//

import SwiftUI

struct MMAlertModifier<AlertModel>: ViewModifier {
    @Binding var alert: AlertModel?

    let title: (AlertModel) -> String
    let message: (AlertModel) -> String
    let buttons: (AlertModel) -> [MMAlertButtonConfig]

    func body(content: Content) -> some View {
        let isPresented = Binding<Bool>(
            get: { alert != nil },
            set: { if !$0 { alert = nil } }
        )

        content.alert(
            alert.map(title) ?? "",
            isPresented: isPresented,
            presenting: alert
        ) { alert in
            let configs = Array(buttons(alert))

            if configs.isEmpty {
                Button("확인") {}
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
    private func makeButton(_ config: MMAlertButtonConfig) -> some View {
        let action: () -> Void = {
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
    func mmAlert<AlertModel>(
        _ alert: Binding<AlertModel?>,
        title: @escaping (AlertModel) -> String,
        message: @escaping (AlertModel) -> String,
        buttons: @escaping (AlertModel) -> [MMAlertButtonConfig] = { _ in [] }
    ) -> some View {
        modifier(
            MMAlertModifier(
                alert: alert,
                title: title,
                message: message,
                buttons: buttons
            )
        )
    }
}
