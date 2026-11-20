import Core
import Supabase

struct SupabaseShoppingListRepository: ShoppingListRepository {
    let client: SupabaseClient

    func items(
        in household: HouseholdID, page: PageRequest
    ) async throws(RepositoryError) -> [ShoppingItem] {
        let rows: [ShoppingItemRow] = try await authorizedRequest(client) {
            try await client.from("shopping_items")
                .select(ShoppingItemRow.columns)
                .eq("household_id", value: household.rawValue)
                .order("created_at", ascending: false)
                .order("id", ascending: false)
                .range(from: page.offset, to: page.offset + page.limit - 1)
                .execute()
                .value
        }
        var items: [ShoppingItem] = []
        items.reserveCapacity(rows.count)
        for row in rows { items.append(try row.domain()) }
        return items
    }

    func add(
        _ draft: ShoppingItemDraft, to household: HouseholdID
    ) async throws(RepositoryError) -> ShoppingItem {
        let row: ShoppingItemRow? = try await authorizedRequest(client) {
            // ON CONFLICT (id) DO NOTHING: a resent draft inserts nothing and returns no row.
            let inserted: [ShoppingItemRow] = try await client.from("shopping_items")
                .upsert(
                    ShoppingItemInsert(draft: draft, household: household),
                    onConflict: "id", returning: .representation, ignoreDuplicates: true
                )
                .select(ShoppingItemRow.columns)
                .execute()
                .value
            if let row = inserted.first { return row }

            // Stored by an earlier attempt of the same draft: read it back.
            let existing: [ShoppingItemRow] = try await client.from("shopping_items")
                .select(ShoppingItemRow.columns)
                .eq("id", value: draft.id.rawValue)
                .eq("household_id", value: household.rawValue)
                .limit(1)
                .execute()
                .value
            return existing.first
        }
        // The id exists but is not visible to this user: it belongs to another household.
        guard let row else { throw .forbidden }
        return try row.domain()
    }
}
