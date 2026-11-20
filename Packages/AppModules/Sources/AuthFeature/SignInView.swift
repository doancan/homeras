import Core
import DesignSystem
import SwiftUI

/// Passwordless sign-in in two steps. The primary action floats in the functional layer; the form
/// is content.
public struct SignInView: View {
    @Bindable var model: SignInModel
    @FocusState private var focusedField: Field?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Field {
        case email
        case code
    }

    public init(model: SignInModel) {
        self.model = model
    }

    public var body: some View {
        Form {
            switch model.step {
            case .email:
                emailStep
            case .code(let address):
                codeStep(address)
            }
        }
        .navigationTitle(title)
        .safeAreaInset(edge: .bottom) { primaryButton }
        .animation(reduceMotion ? nil : .smooth, value: model.step)
        .onAppear { focusedField = .email }
        .onChange(of: model.step) { _, step in
            focusedField = step == .email ? .email : .code
        }
    }

    private var title: Text {
        switch model.step {
        case .email: Text("signIn.email.title", bundle: .module)
        case .code: Text("signIn.code.title", bundle: .module)
        }
    }

    // MARK: Steps

    @ViewBuilder
    private var emailStep: some View {
        Section {
            Text("signIn.email.intro", bundle: .module)
                .foregroundStyle(.secondary)
                .listRowBackground(Color.clear)
        }
        Section {
            TextField(text: $model.email, prompt: Text("signIn.email.prompt", bundle: .module)) {
                Text("signIn.email.label", bundle: .module)
            }
            .textInput(.email)
            .focused($focusedField, equals: .email)
            .submitLabel(.send)
            .onSubmit { Task { await model.requestCode() } }
        } header: {
            Text("signIn.email.label", bundle: .module)
        } footer: {
            errorFooter
        }
    }

    @ViewBuilder
    private func codeStep(_ address: EmailAddress) -> some View {
        Section {
            Text("signIn.code.sentTo \(address.value)", bundle: .module)
                .foregroundStyle(.secondary)
                .listRowBackground(Color.clear)
        }
        Section {
            TextField(text: $model.code, prompt: Text(verbatim: "000000")) {
                Text("signIn.code.label", bundle: .module)
            }
            .textInput(.oneTimeCode)
            .font(.title2.monospacedDigit())
            .focused($focusedField, equals: .code)
            .onChange(of: model.code) { _, _ in
                if model.isCodeComplete { Task { await model.verifyCode() } }
            }
        } header: {
            Text("signIn.code.label", bundle: .module)
        } footer: {
            errorFooter
        }
        Section {
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                let seconds = model.secondsUntilResend()
                Button {
                    Task { await model.resendCode() }
                } label: {
                    if seconds > 0 {
                        Text("signIn.code.resendIn \(seconds)", bundle: .module)
                            .monospacedDigit()
                    } else {
                        Text("signIn.code.resend", bundle: .module)
                    }
                }
                .disabled(seconds > 0 || model.isSubmitting)
            }
            Button {
                model.changeEmail()
            } label: {
                Text("signIn.code.changeEmail", bundle: .module)
            }
            .disabled(model.isSubmitting)
        }
    }

    // MARK: Shared parts

    @ViewBuilder
    private var errorFooter: some View {
        if let message = errorMessage {
            Label {
                Text(message)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
            }
            .foregroundStyle(.red)
        }
    }

    private var errorMessage: String? {
        switch model.error {
        case .invalidEmail(.invalidFormat):
            String(localized: "signIn.email.invalid", bundle: .module)
        case .invalidCode(.invalidFormat):
            String(localized: "signIn.code.invalid", bundle: .module)
        case .invalidEmail(let error), .invalidCode(let error): error.userMessage
        case .auth(let error): error.userMessage
        case nil: nil
        }
    }

    private var primaryButton: some View {
        Button {
            Task {
                switch model.step {
                case .email: await model.requestCode()
                case .code: await model.verifyCode()
                }
            }
        } label: {
            HStack(spacing: 8) {
                if model.isSubmitting {
                    ProgressView()
                }
                primaryLabel
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .disabled(model.isSubmitting)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var primaryLabel: Text {
        switch (model.step, model.isSubmitting) {
        case (.email, false): Text("signIn.email.submit", bundle: .module)
        case (.email, true): Text("signIn.email.submitting", bundle: .module)
        case (.code, false): Text("signIn.code.submit", bundle: .module)
        case (.code, true): Text("signIn.code.submitting", bundle: .module)
        }
    }
}
