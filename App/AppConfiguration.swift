import Foundation
import SupabaseBackend

/// Build-time settings read from Info.plist (filled from Config/*.xcconfig) and validated once at
/// launch, so a misconfigured build fails visibly instead of at the first request.
nonisolated struct AppConfiguration {
    enum Invalid: Error, Equatable {
        case missing(String)
        case insecureURL
    }

    static let urlKey = "HomerasSupabaseURL"
    static let publishableKeyKey = "HomerasSupabasePublishableKey"

    let backend: SupabaseBackendConfiguration

    init(infoDictionary: [String: Any]) throws(Invalid) {
        func value(_ key: String) throws(Invalid) -> String {
            guard let raw = infoDictionary[key] as? String,
                !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { throw .missing(key) }
            return raw
        }

        guard let url = URL(string: try value(Self.urlKey)) else { throw .insecureURL }
        let publishableKey = try value(Self.publishableKeyKey)
        do {
            backend = try SupabaseBackendConfiguration(url: url, publishableKey: publishableKey)
        } catch .url {
            throw .insecureURL
        } catch {
            throw .missing(Self.publishableKeyKey)
        }
    }
}
