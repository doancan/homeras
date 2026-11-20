import Core
import Observation

/// State and actions of the shared shopping list screen.
@Observable
public final class ShoppingListModel {
    public enum LoadState: Equatable {
        case loading
        case loaded
        case failed(RepositoryError)
    }

    public enum AddError: Equatable {
        case invalidName(ValidationError)
        case repository(RepositoryError)
    }

    public let household: Household
    public private(set) var items: [ShoppingItem] = []
    public private(set) var loadState: LoadState = .loading
    public private(set) var canLoadMore = false
    public private(set) var isLoadingMore = false
    public private(set) var isAdding = false
    public private(set) var addError: AddError?
    public var newItemName = "" {
        didSet { if newItemName != oldValue { addError = nil } }
    }

    public var isEmpty: Bool { loadState == .loaded && items.isEmpty }

    private let repository: any ShoppingListRepository
    private var nextPage = PageRequest.first
    /// The draft of the last failed add, resent on retry so the server can deduplicate it.
    private var pendingDraft: ShoppingItemDraft?

    public init(household: Household, repository: any ShoppingListRepository) {
        self.household = household
        self.repository = repository
    }

    /// Loads (or reloads) the first page.
    public func load() async {
        if items.isEmpty { loadState = .loading }
        do {
            let page = try await repository.items(in: household.id, page: .first)
            items = page
            nextPage = PageRequest.first.next
            canLoadMore = page.count == PageRequest.first.limit
            loadState = .loaded
        } catch {
            loadState = .failed(error)
        }
    }

    public func loadMore() async {
        guard canLoadMore, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await repository.items(in: household.id, page: nextPage)
            let known = Set(items.map(\.id))
            items.append(contentsOf: page.filter { !known.contains($0.id) })
            canLoadMore = page.count == nextPage.limit
            nextPage = nextPage.next
        } catch {
            loadState = .failed(error)
        }
    }

    public func addItem() async {
        guard !isAdding else { return }
        let name: ShoppingItemName
        do {
            name = try ShoppingItemName(newItemName)
        } catch {
            addError = .invalidName(error)
            return
        }

        let draft =
            if let pendingDraft, pendingDraft.name == name { pendingDraft } else {
                ShoppingItemDraft(name: name)
            }
        isAdding = true
        defer { isAdding = false }
        do {
            let added = try await repository.add(draft, to: household.id)
            pendingDraft = nil
            items.removeAll { $0.id == added.id }
            items.insert(added, at: 0)
            newItemName = ""
            addError = nil
        } catch {
            pendingDraft = draft
            addError = .repository(error)
        }
    }
}
