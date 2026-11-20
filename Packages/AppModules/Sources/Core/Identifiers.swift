import Foundation

/// The signed-in person, as identified by the auth provider.
public struct UserID: Hashable, Sendable {
    public let rawValue: UUID

    public init(_ rawValue: UUID) {
        self.rawValue = rawValue
    }
}

/// A household: the tenant boundary for all shared data.
public struct HouseholdID: Hashable, Sendable {
    public let rawValue: UUID

    public init(_ rawValue: UUID) {
        self.rawValue = rawValue
    }
}

/// A shopping list entry. Created on the device so retried writes are idempotent.
public struct ShoppingItemID: Hashable, Sendable {
    public let rawValue: UUID

    public init(_ rawValue: UUID) {
        self.rawValue = rawValue
    }
}
