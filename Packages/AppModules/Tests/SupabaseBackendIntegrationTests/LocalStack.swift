import Core
import Foundation
import Testing

@testable import SupabaseBackend

/// Connection to the local Supabase stack started by `make verify-integration`.
struct LocalStack {
    let configuration: SupabaseBackendConfiguration
    let mailpitURL: URL

    init() throws {
        let environment = ProcessInfo.processInfo.environment
        let url = try #require(
            environment["HOMERAS_SUPABASE_URL"].flatMap(URL.init(string:)),
            "Run through `make verify-integration`, which starts Supabase and sets the environment."
        )
        let key = try #require(environment["HOMERAS_SUPABASE_PUBLISHABLE_KEY"])
        mailpitURL = try #require(environment["HOMERAS_MAILPIT_URL"].flatMap(URL.init(string:)))
        configuration = try SupabaseBackendConfiguration(url: url, publishableKey: key)
    }

    /// A backend with its own in-memory session, i.e. a separate device.
    func makeDevice() -> SupabaseServices {
        SupabaseServices(configuration: configuration, sessionStorage: .inMemory)
    }

    /// Signs a fresh user in through the real one-time-code email flow.
    func signInNewUser(on device: SupabaseServices) async throws -> (EmailAddress, UserID) {
        let email = try EmailAddress("user-\(UUID().uuidString.prefix(8))@example.test")
        try await device.auth.requestCode(for: email)
        let code = try await latestCode(for: email)
        let user = try await device.auth.signIn(email: email, code: code)
        return (email, user)
    }

    /// Reads the newest sign-in code sent to `email` from Mailpit.
    func latestCode(for email: EmailAddress) async throws -> OneTimeCode {
        for _ in 0..<20 {
            if let code = try await fetchCode(for: email) { return code }
            try await Task.sleep(for: .milliseconds(250))
        }
        Issue.record("No sign-in email arrived for \(email.value)")
        throw CancellationError()
    }

    private func fetchCode(for email: EmailAddress) async throws -> OneTimeCode? {
        var search = URLComponents(
            url: mailpitURL.appending(path: "api/v1/search"), resolvingAgainstBaseURL: false)
        search?.queryItems = [URLQueryItem(name: "query", value: "to:\"\(email.value)\"")]
        let searchURL = try #require(search?.url)
        let (data, _) = try await URLSession.shared.data(from: searchURL)
        let result = try JSONDecoder().decode(MailpitSearch.self, from: data)
        guard let newest = result.messages.first else { return nil }

        let messageURL = mailpitURL.appending(path: "api/v1/message/\(newest.id)")
        let (messageData, _) = try await URLSession.shared.data(from: messageURL)
        let message = try JSONDecoder().decode(MailpitMessage.self, from: messageData)
        guard let match = message.text.firstMatch(of: /\b(\d{6})\b/) else { return nil }
        return try OneTimeCode(String(match.1))
    }
}

private struct MailpitSearch: Decodable {
    struct Summary: Decodable {
        let id: String
        enum CodingKeys: String, CodingKey { case id = "ID" }
    }
    let messages: [Summary]
}

private struct MailpitMessage: Decodable {
    let text: String
    enum CodingKeys: String, CodingKey { case text = "Text" }
}
