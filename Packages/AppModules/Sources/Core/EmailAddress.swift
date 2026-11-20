import Foundation

/// A normalised (trimmed, lower-cased) email address with a plausible `local@domain.tld` shape.
/// Deliverability is proven by the one-time code, not by this check.
public struct EmailAddress: Hashable, Sendable {
    public static let maximumLength = 254

    public let value: String

    public init(_ raw: String) throws(ValidationError) {
        let normalised = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalised.isEmpty else { throw .empty }
        guard normalised.count <= Self.maximumLength else {
            throw .tooLong(maximum: Self.maximumLength)
        }
        guard normalised.wholeMatch(of: /[^@\s]+@[^@\s]+\.[^@\s]+/) != nil else {
            throw .invalidFormat
        }
        value = normalised
    }
}
