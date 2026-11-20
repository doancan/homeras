import Core
import Foundation
import Testing

@testable import Homeras

@MainActor
@Suite("Root flow", .timeLimit(.minutes(1)))
struct RootModelTests {
    let user = UserID(UUID())

    func household() throws -> Household {
        Household(id: HouseholdID(UUID()), name: try HouseholdName("Yılmaz Ailesi"))
    }

    func makeRoot(auth: FakeAuth, households: FakeHouseholds) -> RootModel {
        RootModel(
            services: AppServices(
                auth: auth, households: households, shoppingList: EmptyShoppingList()))
    }

    /// Waits until the root reaches a screen matching `predicate` (state changes are async).
    func waitFor(_ root: RootModel, _ predicate: (RootModel.Screen) -> Bool) async {
        while !predicate(root.screen) { await Task.yield() }
    }

    @Test func withoutASessionTheUserSignsIn() async {
        let root = makeRoot(auth: FakeAuth(user: nil), households: FakeHouseholds(.success(nil)))

        await root.start()

        #expect(root.screen.isSignIn)
    }

    @Test func aSignedInUserWithoutAHouseholdCreatesOne() async {
        let root = makeRoot(auth: FakeAuth(user: user), households: FakeHouseholds(.success(nil)))

        await root.start()

        #expect(root.screen.isCreateHousehold)
    }

    @Test func aSignedInMemberSeesTheShoppingList() async throws {
        let home = try household()
        let root = makeRoot(auth: FakeAuth(user: user), households: FakeHouseholds(.success(home)))

        await root.start()

        #expect(root.screen.shoppingListHousehold == home)
    }

    @Test func aFailedHouseholdLoadCanBeRetried() async throws {
        let households = FakeHouseholds(.failure(.offline))
        let root = makeRoot(auth: FakeAuth(user: user), households: households)
        await root.start()
        #expect(root.screen == .householdFailed(.offline))

        let home = try household()
        await households.set(.success(home))
        await root.retryHousehold()

        #expect(root.screen.shoppingListHousehold == home)
    }

    @Test func signingInLoadsTheHousehold() async throws {
        let home = try household()
        let root = makeRoot(auth: FakeAuth(user: nil), households: FakeHouseholds(.success(home)))
        await root.start()

        await root.didSignIn(user)

        #expect(root.screen.shoppingListHousehold == home)
    }

    @Test func creatingAHouseholdShowsItsList() async throws {
        let root = makeRoot(auth: FakeAuth(user: user), households: FakeHouseholds(.success(nil)))
        await root.start()
        let home = try household()

        root.didCreateHousehold(home)

        #expect(root.screen.shoppingListHousehold == home)
    }

    @Test func losingTheSessionReturnsToSignIn() async throws {
        let auth = FakeAuth(user: user)
        let root = makeRoot(auth: auth, households: FakeHouseholds(.success(try household())))
        await root.start()
        let listening = Task { await root.observeSession() }

        await auth.emit(nil)
        await waitFor(root) { $0.isSignIn }

        listening.cancel()
        #expect(root.screen.isSignIn)
    }

    @Test func theInitialSessionEventDoesNotReloadTheHousehold() async throws {
        let auth = FakeAuth(user: user)
        let households = FakeHouseholds(.success(try household()))
        let root = makeRoot(auth: auth, households: households)
        await root.start()
        let listening = Task { await root.observeSession() }

        await auth.emit(user)
        await auth.emit(nil)
        await waitFor(root) { $0.isSignIn }

        listening.cancel()
        #expect(await households.loads == 1)
    }

    @Test func signingOutEndsTheSession() async throws {
        let auth = FakeAuth(user: user)
        let root = makeRoot(auth: auth, households: FakeHouseholds(.success(try household())))
        await root.start()

        await root.signOut()

        #expect(await auth.signOutCount == 1)
        #expect(root.screen.isSignIn)
    }
}
