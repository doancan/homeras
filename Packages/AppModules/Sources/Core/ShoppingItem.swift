import Foundation

public struct ShoppingItem: Hashable, Sendable, Identifiable {
    public let id: ShoppingItemID
    public let name: ShoppingItemName
    public let createdAt: Date

    public init(id: ShoppingItemID, name: ShoppingItemName, createdAt: Date) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

/// An item the user wants to add. Keep and resend the same draft on retry: its identifier makes
/// the write idempotent on the server.
public struct ShoppingItemDraft: Hashable, Sendable {
    public let id: ShoppingItemID
    public let name: ShoppingItemName

    public init(name: ShoppingItemName) {
        self.id = ShoppingItemID(UUID())
        self.name = name
    }
}
