import Testing

@testable import Core

@Suite("Shopping item draft")
struct ShoppingItemDraftTests {
    @Test func eachDraftGetsItsOwnIdentifier() throws {
        let name = try ShoppingItemName("Süt")
        #expect(ShoppingItemDraft(name: name).id != ShoppingItemDraft(name: name).id)
    }

    @Test func retryingTheSameDraftKeepsItsIdentifier() throws {
        let draft = ShoppingItemDraft(name: try ShoppingItemName("Süt"))
        let retried = draft
        #expect(retried.id == draft.id)
    }
}
