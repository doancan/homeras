import Foundation

/// Where the backend lives. Only the publishable (anon) key belongs in the app; it is safe to
/// ship because row level security, not the key, protects the data.
public struct SupabaseBackendConfiguration: Sendable, Equatable {
    public enum Invalid: Error, Equatable {
        /// Not HTTPS (plain HTTP is allowed only for a loopback development stack).
        case url
        case publishableKey
    }

    public let url: URL
    public let publishableKey: String

    public init(url: URL, publishableKey: String) throws(Invalid) {
        let isLoopback = ["127.0.0.1", "localhost"].contains(url.host() ?? "")
        switch url.scheme {
        case "https" where url.host() != nil: break
        case "http" where isLoopback: break
        default: throw .url
        }
        guard !publishableKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw .publishableKey
        }
        self.url = url
        self.publishableKey = publishableKey
    }
}
