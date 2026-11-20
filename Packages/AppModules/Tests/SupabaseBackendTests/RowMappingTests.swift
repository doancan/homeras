import Core
import Foundation
import Testing

@testable import SupabaseBackend

@Suite("Row mapping")
struct RowMappingTests {
    @Test func householdRowBecomesAHousehold() throws {
        let id = UUID()
        let household = try HouseholdRow(id: id, name: "Yılmaz Ailesi").domain()
        let expected = Household(id: HouseholdID(id), name: try HouseholdName("Yılmaz Ailesi"))
        #expect(household == expected)
    }

    @Test func aHouseholdRowViolatingDomainRulesIsUnexpected() {
        #expect(throws: RepositoryError.unexpected) {
            try HouseholdRow(id: UUID(), name: "").domain()
        }
    }

    @Test func shoppingItemRowDecodesPostgrestJSON() throws {
        let json = Data(
            """
            {"id":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","name":"Deterjan",
             "created_at":"2026-11-20T08:15:30.123456+00:00"}
            """.utf8)
        let row = try ShoppingItemRow.decoder.decode(ShoppingItemRow.self, from: json)
        let item = try row.domain()
        #expect(item.name.value == "Deterjan")
        #expect(item.createdAt.timeIntervalSince1970.rounded() == 1_795_162_530)
    }

    @Test func insertPayloadUsesColumnNamesAndOnlyClientWritableColumns() throws {
        let draft = ShoppingItemDraft(name: try ShoppingItemName("Süt"))
        let household = HouseholdID(UUID())
        let data = try JSONEncoder().encode(ShoppingItemInsert(draft: draft, household: household))
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: String])
        #expect(Set(object.keys) == ["id", "household_id", "name"])
        #expect(object["household_id"] == household.rawValue.uuidString)
    }
}
