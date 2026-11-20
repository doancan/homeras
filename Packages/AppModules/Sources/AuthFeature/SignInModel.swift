import Core
import Foundation
import Observation

/// Passwordless sign-in: request a code for an email address, then verify it.
@Observable
public final class SignInModel {
    public enum Step: Equatable {
        case email
        case code(EmailAddress)
    }

    public enum Failure: Equatable {
        case invalidEmail(ValidationError)
        case invalidCode(ValidationError)
        case auth(AuthError)
    }

    /// Mirrors the server's per-address resend limit (`auth.email.max_frequency`).
    public static let resendInterval: TimeInterval = 60

    public private(set) var step = Step.email
    public var email = "" {
        didSet { if email != oldValue { error = nil } }
    }
    public var code = "" {
        didSet { if code != oldValue { error = nil } }
    }
    public private(set) var isSubmitting = false
    public private(set) var error: Failure?

    public var isCodeComplete: Bool { (try? OneTimeCode(code)) != nil }

    private let auth: any AuthService
    private let now: () -> Date
    private let onSignedIn: (UserID) -> Void
    private var codeSentAt: Date?

    /// - Parameters:
    ///   - now: The current time; injected so the resend countdown is testable.
    ///   - onSignedIn: Called once after a successful verification.
    public init(
        auth: any AuthService, now: @escaping () -> Date = Date.init,
        onSignedIn: @escaping (UserID) -> Void
    ) {
        self.auth = auth
        self.now = now
        self.onSignedIn = onSignedIn
    }

    public func requestCode() async {
        guard !isSubmitting else { return }
        let address: EmailAddress
        do {
            address = try EmailAddress(email)
        } catch {
            self.error = .invalidEmail(error)
            return
        }
        await send(to: address)
    }

    public func resendCode() async {
        guard case .code(let address) = step, secondsUntilResend() == 0, !isSubmitting else {
            return
        }
        await send(to: address)
    }

    public func verifyCode() async {
        guard case .code(let address) = step, !isSubmitting else { return }
        let oneTimeCode: OneTimeCode
        do {
            oneTimeCode = try OneTimeCode(code)
        } catch {
            self.error = .invalidCode(error)
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }
        do {
            onSignedIn(try await auth.signIn(email: address, code: oneTimeCode))
        } catch {
            code = ""
            self.error = .auth(error)
        }
    }

    public func changeEmail() {
        step = .email
        code = ""
        error = nil
    }

    /// Whole seconds left before another code may be requested; 0 when allowed.
    public func secondsUntilResend() -> Int {
        guard let codeSentAt else { return 0 }
        let remaining = Self.resendInterval - now().timeIntervalSince(codeSentAt)
        return max(0, Int(remaining.rounded(.up)))
    }

    private func send(to address: EmailAddress) async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await auth.requestCode(for: address)
            codeSentAt = now()
            code = ""
            error = nil
            step = .code(address)
        } catch {
            self.error = .auth(error)
        }
    }
}
