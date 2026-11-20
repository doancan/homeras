import Foundation

/// Shared rule for free-text names: trimmed, non-empty, and bounded by Unicode scalar count so the
/// client check matches Postgres `char_length` constraints exactly.
enum TrimmedText {
    static func validate(_ raw: String, maximum: Int) throws(ValidationError) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw .empty }
        guard trimmed.unicodeScalars.count <= maximum else { throw .tooLong(maximum: maximum) }
        return trimmed
    }
}
