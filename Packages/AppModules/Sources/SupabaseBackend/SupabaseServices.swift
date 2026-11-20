import Core
import Foundation
import Supabase

/// Where the signed-in session (access and refresh token) is kept.
public enum SessionStorage: Sendable {
    /// The device Keychain. Use in the app.
    case keychain
    /// Process memory only; every instance is a separate "device". Use in tests and previews.
    case inMemory
}

/// The Supabase implementations of the Core ports, sharing one client.
public final class SupabaseServices: Sendable {
    public let auth: any AuthService
    public let households: any HouseholdRepository
    public let shoppingList: any ShoppingListRepository

    public init(configuration: SupabaseBackendConfiguration, sessionStorage: SessionStorage) {
        let transport = URLSessionConfiguration.default
        transport.timeoutIntervalForRequest = 15
        transport.timeoutIntervalForResource = 30

        let storage: any AuthLocalStorage =
            switch sessionStorage {
            case .keychain: AuthClient.Configuration.defaultLocalStorage
            case .inMemory: InMemorySessionStorage()
            }
        let client = SupabaseClient(
            supabaseURL: configuration.url,
            supabaseKey: configuration.publishableKey,
            options: SupabaseClientOptions(
                auth: .init(storage: storage, emitLocalSessionAsInitialSession: true),
                global: .init(session: URLSession(configuration: transport))
            )
        )
        auth = SupabaseAuthService(client: client)
        households = SupabaseHouseholdRepository(client: client)
        shoppingList = SupabaseShoppingListRepository(client: client)
    }
}
