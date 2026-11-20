import Core
import Foundation
import TestSupport
import Testing

@testable import AuthFeature

actor FakeAuthService: AuthService {
    var requestResults: [Result<Void, AuthError>] = []
    var signInResult: Result<UserID, AuthError> = .success(UserID(UUID()))
    private(set) var requestedEmails: [EmailAddress] = []
    private(set) var verifiedCodes: [OneTimeCode] = []
    private var gate: CheckedContinuation<Void, Never>?
    private var holds = false

    func setRequestResults(_ results: [Result<Void, AuthError>]) { requestResults = results }
    func setSignInResult(_ result: Result<UserID, AuthError>) { signInResult = result }
    func hold() { holds = true }
    func release() {
        holds = false
        gate?.resume()
        gate = nil
    }

    func currentUser() async -> UserID? { nil }
    nonisolated func sessionUpdates() -> AsyncStream<UserID?> { AsyncStream { $0.finish() } }

    func requestCode(for email: EmailAddress) async throws(AuthError) {
        requestedEmails.append(email)
        if holds { await withCheckedContinuation { gate = $0 } }
        try (requestResults.isEmpty ? .success(()) : requestResults.removeFirst()).get()
    }

    func signIn(email: EmailAddress, code: OneTimeCode) async throws(AuthError) -> UserID {
        verifiedCodes.append(code)
        return try signInResult.get()
    }

    func signOut() async throws(AuthError) {}
}

/// A clock the test moves by hand.
@MainActor
final class ManualClock {
    var now = Date(timeIntervalSince1970: 1_800_000_000)
    func advance(by seconds: TimeInterval) { now += seconds }
}

@MainActor
@Suite("Sign-in model", .timeLimit(.minutes(1)))
struct SignInModelTests {
    let service = FakeAuthService()
    let clock = ManualClock()

    func makeModel(onSignedIn: @escaping (UserID) -> Void = { _ in }) -> SignInModel {
        SignInModel(auth: service, now: { [clock] in clock.now }, onSignedIn: onSignedIn)
    }

    func modelAtCodeStep(onSignedIn: @escaping (UserID) -> Void = { _ in }) async -> SignInModel {
        let model = makeModel(onSignedIn: onSignedIn)
        model.email = "Ayse@Example.com"
        await model.requestCode()
        return model
    }

    // MARK: Email step

    @Test func startsAtTheEmailStep() {
        #expect(makeModel().step == .email)
    }

    @Test func requestingACodeMovesToTheCodeStep() async throws {
        let model = await modelAtCodeStep()

        let email = try EmailAddress("ayse@example.com")
        #expect(model.step == .code(email))
        #expect(await service.requestedEmails == [email])
    }

    @Test func aMalformedEmailIsRejectedLocally() async {
        let model = makeModel()
        model.email = "ayse@"

        await model.requestCode()

        #expect(model.error == .invalidEmail(.invalidFormat))
        #expect(model.step == .email)
        #expect(await service.requestedEmails.isEmpty)
    }

    @Test func aRateLimitedRequestStaysOnTheEmailStep() async {
        await service.setRequestResults([.failure(.rateLimited)])
        let model = makeModel()
        model.email = "ayse@example.com"

        await model.requestCode()

        #expect(model.step == .email)
        #expect(model.error == .auth(.rateLimited))
    }

    @Test func aSecondRequestWhileSendingIsIgnored() async {
        await service.hold()
        let model = makeModel()
        model.email = "ayse@example.com"

        let first = Task { await model.requestCode() }
        while await service.requestedEmails.isEmpty { await Task.yield() }
        #expect(model.isSubmitting)
        await model.requestCode()
        await service.release()
        await first.value

        #expect(await service.requestedEmails.count == 1)
    }

    // MARK: Code step

    @Test func aCorrectCodeSignsIn() async {
        let user = UserID(UUID())
        await service.setSignInResult(.success(user))
        var signedIn: UserID?
        let model = await modelAtCodeStep { signedIn = $0 }
        model.code = "123456"

        await model.verifyCode()

        #expect(signedIn == user)
        #expect(model.error == nil)
    }

    @Test func aWrongCodeShowsAGenericErrorAndClearsTheField() async {
        await service.setSignInResult(.failure(.invalidOrExpiredCode))
        var signedIn: UserID?
        let model = await modelAtCodeStep { signedIn = $0 }
        model.code = "000000"

        await model.verifyCode()

        #expect(model.error == .auth(.invalidOrExpiredCode))
        #expect(model.code.isEmpty)
        #expect(signedIn == nil)
    }

    @Test func aMalformedCodeIsRejectedLocally() async {
        let model = await modelAtCodeStep()
        model.code = "12ab"

        await model.verifyCode()

        #expect(model.error == .invalidCode(.invalidFormat))
        #expect(await service.verifiedCodes.isEmpty)
    }

    @Test func aFullCodeIsReadyToSubmit() async {
        let model = await modelAtCodeStep()
        model.code = "12345"
        #expect(!model.isCodeComplete)

        model.code = "123456"

        #expect(model.isCodeComplete)
    }

    @Test func resendingIsBlockedForSixtySeconds() async {
        let model = await modelAtCodeStep()
        clock.advance(by: 59)

        #expect(model.secondsUntilResend() == 1)
        await model.resendCode()

        #expect(await service.requestedEmails.count == 1)
    }

    @Test func resendingIsAllowedAfterSixtySeconds() async {
        let model = await modelAtCodeStep()
        clock.advance(by: 60)

        #expect(model.secondsUntilResend() == 0)
        await model.resendCode()

        #expect(await service.requestedEmails.count == 2)
    }

    @Test func changingTheEmailReturnsToTheEmailStep() async {
        let model = await modelAtCodeStep()
        model.code = "12"

        model.changeEmail()

        #expect(model.step == .email)
        #expect(model.email == "Ayse@Example.com")
        #expect(model.code.isEmpty)
    }

    @Test func catalogIsTranslatedIntoEveryAppLanguage() {
        #expect(LocalizationAudit.keyCount(in: ModuleBundle.bundle, language: "tr") > 0)
        #expect(LocalizationAudit.missingKeys(in: ModuleBundle.bundle).isEmpty)
    }
}
