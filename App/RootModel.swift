import AuthFeature
import Core
import HouseholdFeature
import Observation
import ShoppingFeature

/// Decides which top-level screen is shown: sign-in, household setup, or the household itself.
/// Owns the feature models it creates, so each keeps its state while its screen is visible.
@Observable
final class RootModel {
    enum Screen: Equatable {
        case launching
        case signIn(SignInModel)
        case loadingHousehold
        case householdFailed(RepositoryError)
        case createHousehold(CreateHouseholdModel)
        case shoppingList(ShoppingListModel)

        static func == (lhs: Screen, rhs: Screen) -> Bool {
            switch (lhs, rhs) {
            case (.launching, .launching), (.loadingHousehold, .loadingHousehold): true
            case (.signIn(let a), .signIn(let b)): a === b
            case (.householdFailed(let a), .householdFailed(let b)): a == b
            case (.createHousehold(let a), .createHousehold(let b)): a === b
            case (.shoppingList(let a), .shoppingList(let b)): a === b
            default: false
            }
        }

        var isSignIn: Bool {
            if case .signIn = self { true } else { false }
        }

        var isCreateHousehold: Bool {
            if case .createHousehold = self { true } else { false }
        }

        var shoppingListHousehold: Household? {
            if case .shoppingList(let model) = self { model.household } else { nil }
        }
    }

    private(set) var screen = Screen.launching
    private(set) var signOutError: AuthError?

    private let services: AppServices
    private var currentUser: UserID?

    init(services: AppServices) {
        self.services = services
    }

    /// Restores the stored session and routes to the first screen.
    func start() async {
        currentUser = await services.auth.currentUser()
        if currentUser == nil {
            showSignIn()
        } else {
            await loadHousehold()
        }
    }

    /// Follows session changes for the app's lifetime (e.g. the server revoking the session).
    func observeSession() async {
        for await user in services.auth.sessionUpdates() where user != currentUser {
            currentUser = user
            if user == nil {
                showSignIn()
            } else {
                await loadHousehold()
            }
        }
    }

    func didSignIn(_ user: UserID) async {
        currentUser = user
        await loadHousehold()
    }

    func didCreateHousehold(_ household: Household) {
        screen = .shoppingList(
            ShoppingListModel(household: household, repository: services.shoppingList))
    }

    func retryHousehold() async {
        await loadHousehold()
    }

    func signOut() async {
        do {
            try await services.auth.signOut()
            signOutError = nil
            currentUser = nil
            showSignIn()
        } catch {
            signOutError = error
        }
    }

    func dismissSignOutError() {
        signOutError = nil
    }

    private func loadHousehold() async {
        screen = .loadingHousehold
        do {
            if let household = try await services.households.currentHousehold() {
                didCreateHousehold(household)
            } else {
                screen = .createHousehold(
                    CreateHouseholdModel(repository: services.households) { [weak self] in
                        self?.didCreateHousehold($0)
                    })
            }
        } catch .notAuthenticated {
            currentUser = nil
            showSignIn()
        } catch {
            screen = .householdFailed(error)
        }
    }

    private func showSignIn() {
        screen = .signIn(
            SignInModel(auth: services.auth) { [weak self] user in
                Task { await self?.didSignIn(user) }
            })
    }
}
