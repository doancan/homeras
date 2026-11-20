/// Sign-in and session state. Implemented by a backend adapter; features depend only on this.
public protocol AuthService: Sendable {
    /// The user of the locally stored session, if any. Does not touch the network.
    func currentUser() async -> UserID?
    /// Emits the signed-in user (or `nil`) whenever the session changes, e.g. after sign-out or
    /// when the server revokes the session.
    func sessionUpdates() -> AsyncStream<UserID?>
    /// Sends a one-time code. Succeeds identically whether or not an account exists.
    func requestCode(for email: EmailAddress) async throws(AuthError)
    func signIn(email: EmailAddress, code: OneTimeCode) async throws(AuthError) -> UserID
    func signOut() async throws(AuthError)
}

public protocol HouseholdRepository: Sendable {
    /// The household the signed-in user belongs to, or `nil` if they have none yet.
    func currentHousehold() async throws(RepositoryError) -> Household?
    /// Creates a household with the caller as owner, atomically.
    func createHousehold(named name: HouseholdName) async throws(RepositoryError) -> Household
}

public protocol ShoppingListRepository: Sendable {
    /// Newest first.
    func items(
        in household: HouseholdID, page: PageRequest
    ) async throws(RepositoryError) -> [ShoppingItem]
    /// Idempotent per `draft.id`: resending the same draft never creates a duplicate.
    func add(
        _ draft: ShoppingItemDraft, to household: HouseholdID
    ) async throws(RepositoryError) -> ShoppingItem
}
