import Core
import Foundation
import Supabase

struct SupabaseAuthService: Core.AuthService {
    let client: SupabaseClient

    func currentUser() async -> UserID? {
        client.auth.currentSession.map { UserID($0.user.id) }
    }

    func sessionUpdates() -> AsyncStream<UserID?> {
        let changes = client.auth.authStateChanges
        return AsyncStream { continuation in
            let forwarding = Task {
                for await change in changes {
                    continuation.yield(change.session.map { UserID($0.user.id) })
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in forwarding.cancel() }
        }
    }

    func requestCode(for email: EmailAddress) async throws(Core.AuthError) {
        do {
            try await client.auth.signInWithOTP(email: email.value, shouldCreateUser: true)
        } catch {
            throw ErrorMapping.authError(from: error)
        }
    }

    func signIn(email: EmailAddress, code: OneTimeCode) async throws(Core.AuthError) -> UserID {
        let response: AuthResponse
        do {
            response = try await client.auth.verifyOTP(
                email: email.value, token: code.value, type: .email)
        } catch {
            throw ErrorMapping.authError(from: error)
        }
        guard case .session(let session) = response else { throw .unexpected }
        return UserID(session.user.id)
    }

    /// Revokes every session of the user, on all devices.
    func signOut() async throws(Core.AuthError) {
        do {
            try await client.auth.signOut(scope: .global)
        } catch {
            throw ErrorMapping.authError(from: error)
        }
    }
}
