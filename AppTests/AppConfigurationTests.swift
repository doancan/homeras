import Testing

@testable import Homeras

@Suite("App configuration")
struct AppConfigurationTests {
    @Test func readsTheBackendFromInfoPlistValues() throws {
        let configuration = try AppConfiguration(infoDictionary: [
            "HomerasSupabaseURL": "https://abc.supabase.co",
            "HomerasSupabasePublishableKey": "sb_publishable_x",
        ])
        #expect(configuration.backend.url.absoluteString == "https://abc.supabase.co")
    }

    @Test func missingValuesAreReported() {
        #expect(throws: AppConfiguration.Invalid.missing("HomerasSupabaseURL")) {
            try AppConfiguration(infoDictionary: ["HomerasSupabasePublishableKey": "k"])
        }
    }

    @Test func emptyBuildSettingsCountAsMissing() {
        #expect(throws: AppConfiguration.Invalid.missing("HomerasSupabaseURL")) {
            try AppConfiguration(infoDictionary: [
                "HomerasSupabaseURL": "", "HomerasSupabasePublishableKey": "k",
            ])
        }
    }

    @Test func anInsecureURLIsRejected() {
        #expect(throws: AppConfiguration.Invalid.insecureURL) {
            try AppConfiguration(infoDictionary: [
                "HomerasSupabaseURL": "http://abc.supabase.co",
                "HomerasSupabasePublishableKey": "k",
            ])
        }
    }
}
