import Core
import Foundation
import Testing

@testable import SupabaseBackend

/// End-to-end against the local stack: sign in → create household → shared list, plus tenant
/// isolation between two users. Each test uses fresh users, so tests are independent.
@Suite("Walking skeleton against local Supabase", .serialized, .timeLimit(.minutes(1)))
struct WalkingSkeletonTests {
    let stack: LocalStack

    init() throws {
        stack = try LocalStack()
    }

    @Test func aSignedInUserCreatesAHouseholdAndSharesAList() async throws {
        let device = stack.makeDevice()
        let (_, user) = try await stack.signInNewUser(on: device)
        #expect(await device.auth.currentUser() == user)
        #expect(try await device.households.currentHousehold() == nil)

        let household = try await device.households.createHousehold(
            named: try HouseholdName("Test Evi"))
        #expect(try await device.households.currentHousehold() == household)

        let draft = ShoppingItemDraft(name: try ShoppingItemName("Deterjan"))
        let added = try await device.shoppingList.add(draft, to: household.id)
        #expect(added.id == draft.id)
        #expect(added.name.value == "Deterjan")

        let items = try await device.shoppingList.items(in: household.id, page: .first)
        #expect(items.map(\.id) == [draft.id])
    }

    @Test func resendingTheSameDraftDoesNotDuplicateTheItem() async throws {
        let device = stack.makeDevice()
        _ = try await stack.signInNewUser(on: device)
        let household = try await device.households.createHousehold(named: try HouseholdName("Ev"))
        let draft = ShoppingItemDraft(name: try ShoppingItemName("Süt"))

        let first = try await device.shoppingList.add(draft, to: household.id)
        let retried = try await device.shoppingList.add(draft, to: household.id)

        #expect(retried == first)
        #expect(try await device.shoppingList.items(in: household.id, page: .first).count == 1)
    }

    @Test func aUserCannotCreateASecondHousehold() async throws {
        let device = stack.makeDevice()
        _ = try await stack.signInNewUser(on: device)
        _ = try await device.households.createHousehold(named: try HouseholdName("Birinci"))

        await #expect(throws: RepositoryError.alreadyInHousehold) {
            try await device.households.createHousehold(named: try HouseholdName("İkinci"))
        }
    }

    @Test func anotherUserCannotReadOrWriteTheHouseholdList() async throws {
        let alice = stack.makeDevice()
        _ = try await stack.signInNewUser(on: alice)
        let household = try await alice.households.createHousehold(named: try HouseholdName("A"))
        _ = try await alice.shoppingList.add(
            ShoppingItemDraft(name: try ShoppingItemName("Özel")), to: household.id)

        let bora = stack.makeDevice()
        _ = try await stack.signInNewUser(on: bora)

        #expect(try await bora.households.currentHousehold() == nil)
        #expect(try await bora.shoppingList.items(in: household.id, page: .first).isEmpty)
        await #expect(throws: RepositoryError.forbidden) {
            try await bora.shoppingList.add(
                ShoppingItemDraft(name: try ShoppingItemName("Sızma")), to: household.id)
        }
    }

    @Test func aWrongCodeIsRejectedWithAGenericError() async throws {
        let device = stack.makeDevice()
        let email = try EmailAddress("wrong-\(UUID().uuidString.prefix(8))@example.test")
        try await device.auth.requestCode(for: email)
        let real = try await stack.latestCode(for: email)
        let wrong = try OneTimeCode(real.value == "000000" ? "111111" : "000000")

        await #expect(throws: AuthError.invalidOrExpiredCode) {
            try await device.auth.signIn(email: email, code: wrong)
        }
        #expect(await device.auth.currentUser() == nil)
    }

    @Test func signingOutClearsTheSession() async throws {
        let device = stack.makeDevice()
        _ = try await stack.signInNewUser(on: device)

        try await device.auth.signOut()

        #expect(await device.auth.currentUser() == nil)
        await #expect(throws: RepositoryError.notAuthenticated) {
            try await device.households.currentHousehold()
        }
    }
}
