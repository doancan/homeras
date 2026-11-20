import Core
import DesignSystem
import SwiftUI

/// The household's shared shopping list.
///
/// Content layer: the list rows (no glass). Functional layer: the navigation bar (system glass)
/// and the bottom composer (one `GlassEffectContainer`).
public struct ShoppingListView: View {
    @Bindable var model: ShoppingListModel

    public init(model: ShoppingListModel) {
        self.model = model
    }

    public var body: some View {
        content
            .navigationTitle(Text("shopping.title", bundle: .module))
            .navigationSubtitle(model.household.name.value)
            .safeAreaInset(edge: .bottom) {
                ShoppingComposer(model: model)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            .task { await model.load() }
            .sensoryFeedback(.success, trigger: model.items.first?.id) { old, new in
                old != nil && new != nil && old != new
            }
    }

    @ViewBuilder
    private var content: some View {
        switch model.loadState {
        case .loading:
            ProgressView {
                Text("shopping.loading", bundle: .module)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let error):
            ContentUnavailableView {
                Label {
                    Text("shopping.error.title", bundle: .module)
                } icon: {
                    Image(systemName: "wifi.exclamationmark")
                }
            } description: {
                Text(error.userMessage)
            } actions: {
                Button {
                    Task { await model.load() }
                } label: {
                    Text("action.retry", bundle: .designSystem)
                }
                .buttonStyle(.borderedProminent)
            }
        case .loaded where model.items.isEmpty:
            ContentUnavailableView {
                Label {
                    Text("shopping.empty.title", bundle: .module)
                } icon: {
                    Image(systemName: "cart")
                }
            } description: {
                Text("shopping.empty.description", bundle: .module)
            }
        case .loaded:
            list
        }
    }

    private var list: some View {
        List {
            ForEach(model.items) { item in
                ShoppingItemRow(item: item)
            }
            if model.canLoadMore {
                ProgressView {
                    Text("shopping.loadingMore", bundle: .module)
                }
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)
                .task { await model.loadMore() }
            }
        }
        .listStyle(.plain)
        .refreshable { await model.load() }
    }
}

private struct ShoppingItemRow: View {
    let item: ShoppingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.name.value)
                .font(.body)
            Text(item.createdAt, format: .relative(presentation: .named))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

/// Bottom composer: a glass text field and a prominent add button that share one container.
private struct ShoppingComposer: View {
    @Bindable var model: ShoppingListModel
    @FocusState private var isFocused: Bool

    private var canSubmit: Bool {
        !model.isAdding
            && !model.newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    TextField(
                        text: $model.newItemName,
                        prompt: Text("shopping.composer.placeholder", bundle: .module)
                    ) {
                        Text("shopping.composer.placeholder", bundle: .module)
                    }
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit(submit)
                    .textInput(.sentence)

                    if let message = errorMessage {
                        Label {
                            Text(message)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                        }
                        .font(.footnote)
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isStaticText)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: .rect(cornerRadius: 24))

                Button(action: submit) {
                    Group {
                        if model.isAdding {
                            ProgressView()
                                .accessibilityLabel(
                                    Text("shopping.composer.adding", bundle: .module))
                        } else {
                            Image(systemName: "plus")
                                .font(.title3.weight(.semibold))
                        }
                    }
                    .frame(width: 44, height: 44)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .disabled(!canSubmit)
                .accessibilityLabel(Text("shopping.composer.add", bundle: .module))
            }
        }
        .animation(.snappy, value: errorMessage)
    }

    private var errorMessage: String? {
        switch model.addError {
        case .invalidName(let error): error.userMessage
        case .repository(let error): error.userMessage
        case nil: nil
        }
    }

    private func submit() {
        guard canSubmit else { return }
        Task {
            await model.addItem()
            if model.addError == nil { isFocused = true }
        }
    }
}
