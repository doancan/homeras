import AuthFeature
import DesignSystem
import HouseholdFeature
import ShoppingFeature
import SwiftUI

/// Shows the screen the root model selects. Each screen gets its own navigation stack.
struct RootView: View {
    let root: RootModel

    var body: some View {
        content
            .animation(.smooth, value: root.screen)
            .task { await root.start() }
            .task { await root.observeSession() }
    }

    @ViewBuilder
    private var content: some View {
        switch root.screen {
        case .launching, .loadingHousehold:
            ProgressView()
                .accessibilityLabel(Text("root.loading"))
        case .signIn(let model):
            NavigationStack { SignInView(model: model) }
        case .householdFailed(let error):
            ContentUnavailableView {
                Label {
                    Text("root.householdFailed.title")
                } icon: {
                    Image(systemName: "house")
                }
            } description: {
                Text(error.userMessage)
            } actions: {
                Button {
                    Task { await root.retryHousehold() }
                } label: {
                    Text("action.retry", bundle: .designSystem)
                }
                .buttonStyle(.borderedProminent)
            }
        case .createHousehold(let model):
            NavigationStack { CreateHouseholdView(model: model) }
        case .shoppingList(let model):
            NavigationStack {
                ShoppingListView(model: model)
                    .toolbar { accountMenu }
            }
        }
    }

    private var accountMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button(role: .destructive) {
                    Task { await root.signOut() }
                } label: {
                    Label {
                        Text("root.signOut")
                    } icon: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            } label: {
                Label {
                    Text("root.account")
                } icon: {
                    Image(systemName: "person.crop.circle")
                }
            }
            .alert(
                Text("root.signOutFailed.title"),
                isPresented: Binding(
                    get: { root.signOutError != nil },
                    set: { if !$0 { root.dismissSignOutError() } })
            ) {
                Button(role: .cancel) {
                    root.dismissSignOutError()
                } label: {
                    Text("root.ok")
                }
            } message: {
                Text(root.signOutError?.userMessage ?? "")
            }
        }
    }
}

/// Shown when the build lacks valid backend settings (e.g. Config/Local.xcconfig is missing).
struct MisconfiguredView: View {
    let problem: AppConfiguration.Invalid

    var body: some View {
        ContentUnavailableView {
            Label {
                Text("config.invalid.title")
            } icon: {
                Image(systemName: "wrench.and.screwdriver")
            }
        } description: {
            Text("config.invalid.description")
        }
    }
}
