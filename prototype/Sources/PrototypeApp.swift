import SwiftUI

@main
struct PrototypeApp: App {
    @State private var store: PrototypeStore = {
        let store = PrototypeStore()
        if Demo.value("demo") == "empty" { store.resetToFreshHousehold() }
        if Demo.value("hide") == "1" { store.hidesAmounts = true }
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
    @State private var isQuickAddPresented = Demo.value("demo") == "quickAdd"

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
        .tabViewBottomAccessory {
            Button {
                isQuickAddPresented = true
            } label: {
                Label("Hızlı ekle", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .accessibilityHint("Alışveriş, harcama ya da stok ekle")
        }
        .sheet(isPresented: $isQuickAddPresented) {
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
