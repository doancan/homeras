import Core
import Foundation
import Supabase

// Wire formats of the PostgREST API. Column names live only here.

struct HouseholdRow: Decodable, Equatable {
    let id: UUID
    let name: String

    func domain() throws(RepositoryError) -> Household {
        guard let name = try? HouseholdName(name) else { throw .unexpected }
        return Household(id: HouseholdID(id), name: name)
    }
}

struct ShoppingItemRow: Decodable, Equatable {
    static let columns = "id,name,created_at"
    /// The decoder the SDK uses for PostgREST responses.
    static let decoder = PostgrestClient.Configuration.jsonDecoder

    let id: UUID
    let name: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
    }

    func domain() throws(RepositoryError) -> ShoppingItem {
        guard let name = try? ShoppingItemName(name) else { throw .unexpected }
        return ShoppingItem(id: ShoppingItemID(id), name: name, createdAt: createdAt)
    }
}

/// Only the columns clients are granted to write; the server assigns the rest.
struct ShoppingItemInsert: Encodable {
    let id: UUID
    let householdID: UUID
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case householdID = "household_id"
        case name
    }

    init(draft: ShoppingItemDraft, household: HouseholdID) {
        id = draft.id.rawValue
        householdID = household.rawValue
        name = draft.name.value
    }
}
