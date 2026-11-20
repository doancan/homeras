import SwiftUI

/// Floating confirmation with an undo action. The caller owns timing and dismissal.
public struct UndoToast: View {
    private let title: String
    private let onUndo: () -> Void

    public init(title: String, onUndo: @escaping () -> Void) {
        self.title = title
        self.onUndo = onUndo
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
            Button(action: onUndo) { Text("action.undo", bundle: .designSystem) }
                .font(.subheadline.weight(.semibold))
                .padding(.leading, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .capsule)
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: Text("action.undo", bundle: .designSystem), onUndo)
    }
}
