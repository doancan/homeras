/// A shopping list entry's name: 1–120 characters after trimming.
public struct ShoppingItemName: Hashable, Sendable {
    public static let maximumLength = 120

    public let value: String

    public init(_ raw: String) throws(ValidationError) {
        value = try TrimmedText.validate(raw, maximum: Self.maximumLength)
    }
}
