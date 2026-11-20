import Core
import Foundation

// User-facing text for domain errors. Messages are generic on purpose: they never reveal whether
// an account exists or echo server details.

extension RepositoryError {
    public var userMessage: String {
        switch self {
        case .offline: String(localized: "error.offline", bundle: .module)
        case .notAuthenticated: String(localized: "error.notAuthenticated", bundle: .module)
        case .forbidden: String(localized: "error.forbidden", bundle: .module)
        case .alreadyInHousehold: String(localized: "error.alreadyInHousehold", bundle: .module)
        case .rejected: String(localized: "error.rejected", bundle: .module)
        case .unexpected: String(localized: "error.unexpected", bundle: .module)
        }
    }
}

extension AuthError {
    public var userMessage: String {
        switch self {
        case .invalidOrExpiredCode: String(localized: "error.invalidOrExpiredCode", bundle: .module)
        case .rateLimited: String(localized: "error.rateLimited", bundle: .module)
        case .offline: String(localized: "error.offline", bundle: .module)
        case .unexpected: String(localized: "error.unexpected", bundle: .module)
        }
    }
}

extension ValidationError {
    /// Generic text; features may replace `.invalidFormat` with a field-specific message.
    public var userMessage: String {
        switch self {
        case .empty: String(localized: "validation.empty", bundle: .module)
        case .tooLong(let maximum):
            String(localized: "validation.tooLong \(maximum)", bundle: .module)
        case .invalidFormat: String(localized: "validation.invalidFormat", bundle: .module)
        }
    }
}
