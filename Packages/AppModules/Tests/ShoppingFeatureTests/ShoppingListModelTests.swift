import Core
import Testing

@testable import ShoppingFeature

@MainActor
@Suite("Shopping list model", .timeLimit(.minutes(1)))
struct ShoppingListModelTests {
    let repository = FakeShoppingListRepository()

    func makeModel() throws -> ShoppingListModel {
        ShoppingListModel(household: try Fixtures.household(), repository: repository)
    }

    // MARK: Loading

    @Test func startsInLoadingState() throws {
        #expect(try makeModel().loadState == .loading)
    }

    @Test func loadShowsTheFirstPage() async throws {
        let items = [try Fixtures.item("Süt"), try Fixtures.item("Ekmek", minutesAgo: 5)]
        await repository.setPage(.first, .success(items))
        let model = try makeModel()

        await model.load()

        #expect(model.loadState == .loaded)
        #expect(model.items == items)
    }

    @Test func loadWithNoItemsIsEmpty() async throws {
        let model = try makeModel()

        await model.load()

        #expect(model.loadState == .loaded)
        #expect(model.isEmpty)
    }

    @Test func loadFailureIsShownWithItsReason() async throws {
        await repository.setPage(.first, .failure(.offline))
        let model = try makeModel()

        await model.load()

        #expect(model.loadState == .failed(.offline))
    }

    @Test func reloadAfterFailureRecovers() async throws {
        await repository.setPage(.first, .failure(.offline))
        let model = try makeModel()
        await model.load()
        await repository.setPage(.first, .success([try Fixtures.item("Süt")]))

        await model.load()

        #expect(model.loadState == .loaded)
        #expect(model.items.count == 1)
    }

    // MARK: Pagination

    @Test func aFullPageOffersMore() async throws {
        let fullPage = try (0..<PageRequest.maximumLimit).map { try Fixtures.item("Ürün \($0)") }
        await repository.setPage(.first, .success(fullPage))
        let model = try makeModel()

        await model.load()

        #expect(model.canLoadMore)
    }

    @Test func aShortPageOffersNoMore() async throws {
        await repository.setPage(.first, .success([try Fixtures.item("Süt")]))
        let model = try makeModel()

        await model.load()

        #expect(!model.canLoadMore)
    }

    @Test func loadMoreAppendsTheNextPage() async throws {
        let fullPage = try (0..<PageRequest.maximumLimit).map { try Fixtures.item("Ürün \($0)") }
        let last = try Fixtures.item("En eski", minutesAgo: 60)
        await repository.setPage(.first, .success(fullPage))
        await repository.setPage(PageRequest.first.next, .success([last]))
        let model = try makeModel()
        await model.load()

        await model.loadMore()

        #expect(model.items.count == PageRequest.maximumLimit + 1)
        #expect(model.items.last == last)
        #expect(!model.canLoadMore)
    }

    // MARK: Adding

    @Test func addingPrependsTheTrimmedItemAndClearsTheField() async throws {
        await repository.setPage(.first, .success([try Fixtures.item("Ekmek")]))
        let model = try makeModel()
        await model.load()
        model.newItemName = "  Deterjan  "

        await model.addItem()

        #expect(model.items.first?.name.value == "Deterjan")
        #expect(model.newItemName.isEmpty)
        #expect(model.addError == nil)
    }

    @Test func addingABlankNameIsRejectedLocally() async throws {
        let model = try makeModel()
        model.newItemName = "   "

        await model.addItem()

        #expect(model.addError == .invalidName(.empty))
        #expect(await repository.addedDrafts.isEmpty)
    }

    @Test func aSecondSubmitWhileAddingIsIgnored() async throws {
        await repository.holdAdds()
        let model = try makeModel()
        model.newItemName = "Süt"

        let first = Task { await model.addItem() }
        while await repository.addedDrafts.isEmpty { await Task.yield() }
        #expect(model.isAdding)
        await model.addItem()
        await repository.releaseAdd()
        await first.value

        #expect(await repository.addedDrafts.count == 1)
        #expect(!model.isAdding)
    }

    @Test func aFailedAddKeepsTheTextAndReportsTheReason() async throws {
        await repository.setAddResults([.failure(.offline)])
        let model = try makeModel()
        model.newItemName = "Süt"

        await model.addItem()

        #expect(model.newItemName == "Süt")
        #expect(model.addError == .repository(.offline))
        #expect(model.items.isEmpty)
    }

    @Test func retryingAFailedAddResendsTheSameDraft() async throws {
        await repository.setAddResults([.failure(.offline), .success(())])
        let model = try makeModel()
        model.newItemName = "Süt"

        await model.addItem()
        await model.addItem()

        let drafts = await repository.addedDrafts
        #expect(drafts.count == 2)
        #expect(drafts[0].id == drafts[1].id)
        #expect(model.items.count == 1)
    }

    @Test func editingTheNameAfterAFailureStartsANewDraft() async throws {
        await repository.setAddResults([.failure(.offline), .success(())])
        let model = try makeModel()
        model.newItemName = "Süt"
        await model.addItem()
        model.newItemName = "Yoğurt"

        await model.addItem()

        let drafts = await repository.addedDrafts
        #expect(drafts[0].id != drafts[1].id)
        #expect(model.items.first?.name.value == "Yoğurt")
    }
}
