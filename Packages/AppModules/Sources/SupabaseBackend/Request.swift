import Core
import Supabase

/// Runs a data request on behalf of the signed-in user and maps every failure to the domain.
///
/// The session is checked (and refreshed when expired) first: without it the SDK would fall back
/// to the anon key and the database would answer "permission denied" instead of "signed out".
func authorizedRequest<T>(
    _ client: SupabaseClient, _ operation: () async throws -> T
) async throws(RepositoryError) -> T {
    do {
        _ = try await client.auth.session
        return try await operation()
    } catch {
        throw ErrorMapping.repositoryError(from: error)
    }
}
