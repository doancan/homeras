import Core
import Foundation

actor FakeAuth: AuthService {
    var user: UserID?
    private(set) var signOutCount = 0
    // Buffered from the start, so events emitted before anyone listens are not lost.
    private let updates: AsyncStream<UserID?>
    private let continuation: AsyncStream<UserID?>.Continuation

    init(user: UserID?) {
        self.user = user
        (updates, continuation) = AsyncStream<UserID?>.makeStream()
    }

    func currentUser() async -> UserID? { user }

    nonisolated func sessionUpdates() -> AsyncStream<UserID?> { updates }

    /// Simulates the server ending or changing the session.
    func emit(_ user: UserID?) {
        self.user = user
        continuation.yield(user)
    }

    func requestCode(for email: EmailAddress) async throws(AuthError) {}
    func signIn(email: EmailAddress, code: OneTimeCode) async throws(AuthError) -> UserID {
        UserID(UUID())
    }
    func signOut() async throws(AuthError) {
        signOutCount += 1
        emit(nil)
    }
}

actor FakeHouseholds: HouseholdRepository {
    var result: Result<Household?, RepositoryError>
    private(set) var loads = 0

    init(_ result: Result<Household?, RepositoryError>) { self.result = result }

    func set(_ result: Result<Household?, RepositoryError>) { self.result = result }

    func currentHousehold() async throws(RepositoryError) -> Household? {
        loads += 1
        return try result.get()
    }

    func createHousehold(named name: HouseholdName) async throws(RepositoryError) -> Household {
        Household(id: HouseholdID(UUID()), name: name)
    }
}

struct EmptyShoppingList: ShoppingListRepository {
    func items(
        in household: HouseholdID, page: PageRequest
    ) async throws(RepositoryError) -> [ShoppingItem] { [] }

    func add(
        _ draft: ShoppingItemDraft, to household: HouseholdID
    ) async throws(RepositoryError) -> ShoppingItem {
        ShoppingItem(id: draft.id, name: draft.name, createdAt: .now)
    }
}
