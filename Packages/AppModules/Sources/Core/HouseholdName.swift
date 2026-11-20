/// A household's display name: 1–60 characters after trimming.
public struct HouseholdName: Hashable, Sendable {
    public static let maximumLength = 60

    public let value: String

    public init(_ raw: String) throws(ValidationError) {
        value = try TrimmedText.validate(raw, maximum: Self.maximumLength)
    }
}
