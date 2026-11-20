import Foundation
import Testing

@testable import SupabaseBackend

@Suite("Backend configuration")
struct ConfigurationTests {
    @Test func acceptsHTTPSWithAKey() throws {
        let url = try #require(URL(string: "https://abc.supabase.co"))
        let configuration = try SupabaseBackendConfiguration(
            url: url, publishableKey: "sb_publishable_x")
        #expect(configuration.url == url)
    }

    @Test(arguments: ["http://127.0.0.1:54721", "http://localhost:54721"])
    func allowsPlainHTTPOnlyForLoopback(_ raw: String) throws {
        let url = try #require(URL(string: raw))
        #expect(throws: Never.self) {
            try SupabaseBackendConfiguration(url: url, publishableKey: "key")
        }
    }

    @Test(arguments: ["http://abc.supabase.co", "ftp://abc.supabase.co", "abc.supabase.co"])
    func rejectsInsecureOrMalformedURLs(_ raw: String) throws {
        let url = try #require(URL(string: raw))
        #expect(throws: SupabaseBackendConfiguration.Invalid.url) {
            try SupabaseBackendConfiguration(url: url, publishableKey: "key")
        }
    }

    @Test func rejectsABlankKey() throws {
        let url = try #require(URL(string: "https://abc.supabase.co"))
        #expect(throws: SupabaseBackendConfiguration.Invalid.publishableKey) {
            try SupabaseBackendConfiguration(url: url, publishableKey: "  ")
        }
    }
}
