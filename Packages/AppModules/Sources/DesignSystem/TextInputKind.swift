import SwiftUI

/// The kind of text a field collects. Sets the keyboard, autofill content type and capitalisation
/// together so every field of a kind behaves the same. The iOS-only modifiers are compiled out on
/// macOS, where the package is only built for tests.
public enum TextInputKind {
    /// Free text such as names of items or households.
    case sentence
    case email
    case oneTimeCode
}

extension View {
    public func textInput(_ kind: TextInputKind) -> some View {
        modifier(TextInputModifier(kind: kind))
    }
}

private struct TextInputModifier: ViewModifier {
    let kind: TextInputKind

    func body(content: Content) -> some View {
        #if os(iOS)
            switch kind {
            case .sentence:
                content
                    .textInputAutocapitalization(.sentences)
            case .email:
                content
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            case .oneTimeCode:
                content
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .autocorrectionDisabled()
            }
        #else
            content.autocorrectionDisabled(kind != .sentence)
        #endif
    }
}
