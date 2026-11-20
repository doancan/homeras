import SwiftUI

/// Tinted rounded-square symbol used as the leading mark of rows and cards.
public struct IconBadge: View {
    private let symbol: String
    private let tint: Color
    @ScaledMetric(relativeTo: .body) private var size = 32

    public init(symbol: String, tint: Color) {
        self.symbol = symbol
        self.tint = tint
    }

    public var body: some View {
        Image(systemName: symbol)
            .font(.callout.weight(.medium))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.14), in: .rect(cornerRadius: 8))
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .accessibilityHidden(true)
    }
}
