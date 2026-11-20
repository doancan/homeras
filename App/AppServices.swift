import Core
import SupabaseBackend

/// The port implementations the app runs with. The only place that knows which backend is used.
nonisolated struct AppServices: Sendable {
    let auth: any AuthService
    let households: any HouseholdRepository
    let shoppingList: any ShoppingListRepository

    static func live(_ configuration: AppConfiguration) -> AppServices {
        let supabase = SupabaseServices(
            configuration: configuration.backend, sessionStorage: .keychain)
        return AppServices(
            auth: supabase.auth, households: supabase.households,
            shoppingList: supabase.shoppingList)
    }
}
