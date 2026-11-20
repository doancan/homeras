import Core
import Supabase

struct SupabaseHouseholdRepository: HouseholdRepository {
    private struct CreateParams: Encodable {
        let householdName: String
        enum CodingKeys: String, CodingKey { case householdName = "household_name" }
    }

    let client: SupabaseClient

    func currentHousehold() async throws(RepositoryError) -> Household? {
        let rows: [HouseholdRow] = try await authorizedRequest(client) {
            try await client.from("households")
                .select("id,name")
                .order("created_at")
                .limit(1)
                .execute()
                .value
        }
        return try rows.first?.domain()
    }

    func createHousehold(named name: HouseholdName) async throws(RepositoryError) -> Household {
        let params = CreateParams(householdName: name.value)
        let row: HouseholdRow = try await authorizedRequest(client) {
            try await client.rpc("create_household", params: params).execute().value
        }
        return try row.domain()
    }
}
