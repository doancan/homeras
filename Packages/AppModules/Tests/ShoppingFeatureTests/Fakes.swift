import Core
import Foundation

/// In-memory repository whose results each test scripts. `add` can be held open with a gate to
/// observe in-flight behaviour.
actor FakeShoppingListRepository: ShoppingListRepository {
    var pages: [PageRequest: Result<[ShoppingItem], RepositoryError>] = [:]
    var addResults: [Result<Void, RepositoryError>] = []
    private(set) var requestedPages: [PageRequest] = []
    private(set) var addedDrafts: [ShoppingItemDraft] = []
    private var addGate: CheckedContinuation<Void, Never>?
    private var holdsAdds = false

    func setPage(_ page: PageRequest, _ result: Result<[ShoppingItem], RepositoryError>) {
        pages[page] = result
    }

    func setAddResults(_ results: [Result<Void, RepositoryError>]) {
        addResults = results
    }

    func holdAdds() {
        holdsAdds = true
    }

    func releaseAdd() {
        holdsAdds = false
        addGate?.resume()
        addGate = nil
    }

    func items(
        in household: HouseholdID, page: PageRequest
    ) async throws(RepositoryError) -> [ShoppingItem] {
        requestedPages.append(page)
        return try (pages[page] ?? .success([])).get()
    }

    func add(
        _ draft: ShoppingItemDraft, to household: HouseholdID
    ) async throws(RepositoryError) -> ShoppingItem {
        addedDrafts.append(draft)
        if holdsAdds {
            await withCheckedContinuation { addGate = $0 }
        }
        let result = addResults.isEmpty ? .success(()) : addResults.removeFirst()
        try result.get()
        return ShoppingItem(id: draft.id, name: draft.name, createdAt: .now)
    }
}

enum Fixtures {
    static func household() throws -> Household {
        Household(id: HouseholdID(UUID()), name: try HouseholdName("Yılmaz Ailesi"))
    }

    static func item(_ name: String, minutesAgo: Double = 0) throws -> ShoppingItem {
        ShoppingItem(
            id: ShoppingItemID(UUID()),
            name: try ShoppingItemName(name),
            createdAt: Date(timeIntervalSinceNow: -minutesAgo * 60))
    }
}
