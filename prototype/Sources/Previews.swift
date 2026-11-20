import SwiftUI

// Live canvas previews: open any screen file in Xcode and keep the canvas visible
// (Editor ▸ Canvas, ⌥⌘↩). The canvas refreshes on every saved change; no Run needed.

private extension PrototypeStore {
    static func sample(fresh: Bool = false, hidden: Bool = false) -> PrototypeStore {
        let store = PrototypeStore()
        if fresh { store.resetToFreshHousehold() }
        store.hidesAmounts = hidden
        return store
    }
}

#Preview("Uygulama") {
    RootTabs()
        .environment(PrototypeStore.sample())
        .tint(Color.accentColor)
}

#Preview("Bugün") {
    TodayView(selection: .constant(.today))
        .environment(PrototypeStore.sample())
}

#Preview("Bugün · ilk açılış") {
    TodayView(selection: .constant(.today))
        .environment(PrototypeStore.sample(fresh: true))
}

#Preview("Bugün · tutarlar gizli") {
    TodayView(selection: .constant(.today))
        .environment(PrototypeStore.sample(hidden: true))
}

#Preview("Bugün · koyu") {
    TodayView(selection: .constant(.today))
        .environment(PrototypeStore.sample())
        .preferredColorScheme(.dark)
}

#Preview("Bugün · en büyük yazı") {
    TodayView(selection: .constant(.today))
        .environment(PrototypeStore.sample())
        .dynamicTypeSize(.accessibility5)
}

#Preview("Alışveriş") {
    ShoppingView()
        .environment(PrototypeStore.sample())
}

#Preview("Alışverişi bitir") {
    let store = PrototypeStore.sample()
    for entry in store.shopping.prefix(3) { store.toggleCart(entry) }
    return FinishShoppingSheet()
        .environment(store)
}

#Preview("Ev") {
    HomeInventoryView()
        .environment(PrototypeStore.sample())
}

#Preview("Eşya detayı") {
    let store = PrototypeStore.sample()
    return NavigationStack {
        BelongingDetailView(item: store.belongings[1])
    }
    .environment(store)
}

#Preview("Bütçe") {
    BudgetView()
        .environment(PrototypeStore.sample())
}

#Preview("Ara") {
    SearchView()
        .environment(PrototypeStore.sample())
}

#Preview("Hızlı ekle") {
    QuickAddSheet()
        .environment(PrototypeStore.sample())
}

#Preview("Aile") {
    FamilySheet()
        .environment(PrototypeStore.sample())
}
