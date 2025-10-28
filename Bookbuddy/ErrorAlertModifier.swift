//
//  ErrorAlertModifier.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 27/10/2025.
//

import SwiftUI

/// A reusable view modifier for displaying error alerts consistently across the app
struct ErrorAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                Button("OK") { }
            } message: {
                Text(message)
            }
    }
}

extension View {
    /// Shows an error alert with the specified title and message
    /// - Parameters:
    ///   - title: The alert title (e.g., "Error", "Failed to Save")
    ///   - isPresented: Binding to control alert visibility
    ///   - message: The error message to display
    func errorAlert(title: String, isPresented: Binding<Bool>, message: String) -> some View {
        modifier(ErrorAlertModifier(isPresented: isPresented, title: title, message: message))
    }
}
