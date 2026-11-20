import SwiftUI

@main
struct PrototypeApp: App {
    @State private var store: PrototypeStore = {
        let store = PrototypeStore()
        if Demo.value("demo") == "empty" { store.resetToFreshHousehold() }
        if Demo.value("hide") == "1" { store.hidesAmounts = true }
        if Demo.value("demo") == "quickAdd" { store.isQuickAddPresented = true }
        if Demo.value("toast") == "1" { store.lastAdded = store.expenses.first }
        return store
    }()

    var body: some Scene {
        WindowGroup {
            RootTabs()
                .environment(store)
                .tint(Color.accentColor)
        }
    }
}

enum AppTab: Hashable {
    case today, shopping, home, budget, search
}

/// Functional layer: the system tab bar (glass), the search tab and the quick-add accessory.
/// Every screen inside is content layer.
struct RootTabs: View {
    @Environment(PrototypeStore.self) private var store
    @State private var selection = Demo.initialTab

    var body: some View {
        TabView(selection: $selection) {
            Tab("Bugün", systemImage: "square.grid.2x2", value: AppTab.today) {
                TodayView(selection: $selection)
            }
            Tab("Alışveriş", systemImage: "cart", value: AppTab.shopping) {
                ShoppingView()
            }
            .badge(store.shopping.filter { !$0.isInCart }.count)
            Tab("Ev", systemImage: "house", value: AppTab.home) {
                HomeInventoryView()
            }
            Tab("Bütçe", systemImage: "chart.pie", value: AppTab.budget) {
                BudgetView()
            }
            Tab("Ara", systemImage: "magnifyingglass", value: AppTab.search, role: .search) {
                SearchView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .overlay(alignment: .bottom) {
            // Above the tab bar: never covers the navigation bar's actions, and is in thumb reach.
            if let last = store.lastAdded {
                UndoToast(expense: last)
                    .padding(.bottom, 96)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task(id: last.id) {
                        try? await Task.sleep(for: .seconds(5))  // auto-dismiss; cancellation just ends it early
                        withAnimation { if store.lastAdded?.id == last.id { store.lastAdded = nil } }
                    }
            }
        }
        .animation(.snappy, value: store.lastAdded?.id)
        .sheet(isPresented: Bindable(store).isQuickAddPresented) {
            QuickAddSheet()
                .presentationDetents([.medium, .large])
        }
    }
}

/// Launch arguments for walking through the prototype without taps, e.g.
/// `-tab shopping -demo finish`. Prototype only.
enum Demo {
    static func value(_ key: String) -> String? {
        UserDefaults.standard.string(forKey: key)
    }

    static var initialTab: AppTab {
        switch value("tab") {
        case "shopping": .shopping
        case "home": .home
        case "budget": .budget
        case "search": .search
        default: .today
        }
    }
}

/// Confirms a saved expense and offers undo for a few seconds (Dime-style confirmation).
struct UndoToast: View {
    @Environment(PrototypeStore.self) private var store
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(expense.amount.lira) \(expense.category)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                Text("eklendi")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button("Geri al") { withAnimation { store.undoLastAdded() } }
                .font(.subheadline.weight(.semibold))
                .padding(.leading, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .capsule)
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: "Geri al") { store.undoLastAdded() }
    }
}
