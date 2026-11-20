import Core
import DesignSystem
import SwiftUI

/// First-run step: name the household. The submit button floats in the functional layer.
public struct CreateHouseholdView: View {
    @Bindable var model: CreateHouseholdModel
    @FocusState private var isNameFocused: Bool

    public init(model: CreateHouseholdModel) {
        self.model = model
    }

    public var body: some View {
        Form {
            Section {
                Text("household.create.intro", bundle: .module)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            Section {
                TextField(
                    text: $model.name,
                    prompt: Text("household.create.namePrompt", bundle: .module)
                ) {
                    Text("household.create.nameLabel", bundle: .module)
                }
                .textInput(.sentence)
                .focused($isNameFocused)
                .submitLabel(.done)
                .onSubmit(submit)
            } header: {
                Text("household.create.nameLabel", bundle: .module)
            } footer: {
                if let message = errorMessage {
                    Label {
                        Text(message)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                    .foregroundStyle(.red)
                } else {
                    Text(
                        "household.create.nameFooter \(HouseholdName.maximumLength)",
                        bundle: .module)
                }
            }
        }
        .navigationTitle(Text("household.create.title", bundle: .module))
        .safeAreaInset(edge: .bottom) {
            Button(action: submit) {
                HStack(spacing: 8) {
                    if model.isSubmitting {
                        ProgressView()
                    }
                    Text(
                        model.isSubmitting
                            ? "household.create.submitting" : "household.create.submit",
                        bundle: .module)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(model.isSubmitting)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .onAppear { isNameFocused = true }
    }

    private var errorMessage: String? {
        switch model.error {
        case .invalidName(let error): error.userMessage
        case .repository(let error): error.userMessage
        case nil: nil
        }
    }

    private func submit() {
        Task { await model.create() }
    }
}
