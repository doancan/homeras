/// Failures of the sign-in flow. Cases are deliberately coarse so the UI never reveals whether an
/// account exists for an email address.
public enum AuthError: Error, Equatable, Sendable {
    case invalidOrExpiredCode
    case rateLimited
    case offline
    case unexpected
}

/// Failures of data access, independent of the backend behind the repository.
public enum RepositoryError: Error, Equatable, Sendable {
    case offline
    case notAuthenticated
    /// Signed in, but not allowed to touch this data (e.g. another household's rows).
    case forbidden
    /// MVP rule: a user belongs to at most one household.
    case alreadyInHousehold
    /// The server rejected the input (a constraint the client did not catch).
    case rejected
    case unexpected
}
