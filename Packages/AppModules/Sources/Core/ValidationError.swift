/// Why a raw input could not become a validated domain value.
public enum ValidationError: Error, Equatable, Sendable {
    case empty
    case tooLong(maximum: Int)
    case invalidFormat
}
