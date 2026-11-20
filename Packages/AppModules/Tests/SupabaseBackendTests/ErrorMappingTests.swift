import Core
import Foundation
import Supabase
import Testing

@testable import SupabaseBackend

@Suite("Error mapping")
struct ErrorMappingTests {
    // MARK: Repository errors

    @Test(arguments: [
        ("HM001", RepositoryError.alreadyInHousehold),
        ("42501", .forbidden),
        ("23514", .rejected),
        ("23505", .rejected),
        ("22001", .rejected),
        ("PGRST301", .notAuthenticated),
        ("PGRST303", .notAuthenticated),
        ("XX000", .unexpected),
    ])
    func postgresCodesMapToRepositoryErrors(code: String, expected: RepositoryError) {
        let error = PostgrestError(code: code, message: "detail that must not reach the user")
        #expect(ErrorMapping.repositoryError(from: error) == expected)
    }

    @Test(arguments: [
        URLError.Code.notConnectedToInternet, .networkConnectionLost, .timedOut,
        .cannotConnectToHost, .cannotFindHost, .dataNotAllowed,
    ])
    func connectivityFailuresAreOfflineForRepositories(_ code: URLError.Code) {
        #expect(ErrorMapping.repositoryError(from: URLError(code)) == .offline)
    }

    @Test func aMissingSessionIsNotAuthenticated() {
        let error = Auth.AuthError.sessionMissing
        #expect(ErrorMapping.repositoryError(from: error) == .notAuthenticated)
    }

    @Test func unknownErrorsAreUnexpected() {
        struct Unknown: Error {}
        #expect(ErrorMapping.repositoryError(from: Unknown()) == .unexpected)
    }

    // MARK: Auth errors

    @Test(arguments: [
        ("otp_expired", Core.AuthError.invalidOrExpiredCode),
        ("over_request_rate_limit", .rateLimited),
        ("over_email_send_rate_limit", .rateLimited),
        ("email_address_invalid", .unexpected),
    ])
    func authApiCodesMapToAuthErrors(code: String, expected: Core.AuthError) throws {
        #expect(ErrorMapping.authError(from: try apiError(code: code, status: 400)) == expected)
    }

    @Test func http429IsRateLimitedWhateverTheCode() throws {
        let error = try apiError(code: "unknown", status: 429)
        #expect(ErrorMapping.authError(from: error) == .rateLimited)
    }

    @Test func connectivityFailuresAreOfflineForAuth() {
        #expect(ErrorMapping.authError(from: URLError(.notConnectedToInternet)) == .offline)
    }

    private func apiError(code: String, status: Int) throws -> Auth.AuthError {
        let url = try #require(URL(string: "http://127.0.0.1/auth/v1/verify"))
        let response = try #require(
            HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil))
        return .api(
            message: "server text", errorCode: ErrorCode(code), underlyingData: Data(),
            underlyingResponse: response)
    }
}
