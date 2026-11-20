import Foundation

/// The 6-digit sign-in code sent by email.
public struct OneTimeCode: Hashable, Sendable {
    public static let length = 6

    public let value: String

    public init(_ raw: String) throws(ValidationError) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw .empty }
        guard trimmed.count == Self.length, trimmed.allSatisfy({ $0.isASCII && $0.isNumber }) else {
            throw .invalidFormat
        }
        value = trimmed
    }
}
