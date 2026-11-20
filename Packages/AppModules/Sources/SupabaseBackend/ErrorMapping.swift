import Core
import Foundation
import Supabase
import os

/// Translates SDK and transport errors into domain errors. Server messages are logged privately
/// and never surfaced: they can contain user data or reveal whether an account exists.
enum ErrorMapping {
    static let logger = Logger(subsystem: "app.homeras", category: "SupabaseBackend")

    /// A row from the server broke a domain rule the database should already enforce.
    static func invalidRow(_ table: String, id: UUID) -> RepositoryError {
        logger.error(
            "Invalid \(table, privacy: .public) row \(id.uuidString, privacy: .private) violates domain rules"
        )
        return .unexpected
    }

    static func repositoryError(from error: any Error) -> RepositoryError {
        if isConnectivityFailure(error) { return .offline }
        if let error = error as? PostgrestError {
            switch error.code {
            case "HM001": return .alreadyInHousehold
            case "42501": return .forbidden
            case "23502", "23505", "23514", "22001": return .rejected
            case "PGRST301", "PGRST302", "PGRST303": return .notAuthenticated
            default:
                logger.error(
                    "Unexpected PostgREST error \(error.code ?? "nil", privacy: .public): \(error.message, privacy: .private)"
                )
                return .unexpected
            }
        }
        if let error = error as? Auth.AuthError, error.errorCode == .sessionNotFound {
            return .notAuthenticated
        }
        logger.error("Unexpected repository error: \(String(describing: error), privacy: .private)")
        return .unexpected
    }

    static func authError(from error: any Error) -> Core.AuthError {
        if isConnectivityFailure(error) { return .offline }
        if case .api(_, let code, _, let response) = error as? Auth.AuthError {
            if response.statusCode == 429 { return .rateLimited }
            switch code {
            case .otpExpired: return .invalidOrExpiredCode
            case .overRequestRateLimit, .overEmailSendRateLimit: return .rateLimited
            default:
                logger.error("Unexpected auth error code \(code.rawValue, privacy: .public)")
                return .unexpected
            }
        }
        logger.error("Unexpected auth error: \(String(describing: error), privacy: .private)")
        return .unexpected
    }

    private static func isConnectivityFailure(_ error: any Error) -> Bool {
        guard let error = error as? URLError else { return false }
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost,
            .cannotFindHost, .dataNotAllowed, .internationalRoamingOff:
            return true
        default:
            return false
        }
    }
}
