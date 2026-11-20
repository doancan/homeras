import SwiftUI

/// Shared list grouped like a store walk. Checked items drop into "Sepette"; "Bitir" closes the
/// loop into stock and budget.
struct ShoppingView: View {
    @Environment(PrototypeStore.self) private var store
    @State private var isFinishPresented = false

    private var pending: [ShoppingEntry] { store.shopping.filter { !$0.isInCart } }
    private var inCart: [ShoppingEntry] { store.shopping.filter(\.isInCart) }
    /// A store walk, not the alphabet: produce first, cleaning last, anything else after.
    private static let aisleOrder = ["Manav", "Süt ve kahvaltı", "Temizlik", "Stoktan", "Diğer"]

    private var groups: [(String, [ShoppingEntry])] {
        Dictionary(grouping: pending, by: \.category)
            .sorted { lhs, rhs in
                let left = Self.aisleOrder.firstIndex(of: lhs.key) ?? Self.aisleOrder.count
                let right = Self.aisleOrder.firstIndex(of: rhs.key) ?? Self.aisleOrder.count
                return left == right ? lhs.key.localizedStandardCompare(rhs.key) == .orderedAscending : left < right
            }
            .map { ($0.key, $0.value) }
    }
    private var suggestions: [StockItem] { store.lowStock.filter { !store.isOnList($0) } }

    var body: some View {
        NavigationStack {
            List {
                let usuals = store.usuals.filter { name in !store.shopping.contains { $0.name == name && !$0.isInCart } }
                if !usuals.isEmpty {
                    Section {
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(usuals, id: \.self) { name in
                                    Button {
                                        withAnimation { store.addToList(usual: name) }
                                    } label: {
                                        Label(name, systemImage: "arrow.counterclockwise")
                                            .font(.subheadline)
                                    }
                                    .buttonStyle(.bordered)
                                    .buttonBorderShape(.capsule)
                                    .accessibilityLabel("\(name) tekrar ekle")
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } header: {
                        Text("Sık aldıklarınız")
                    }
                }

                if !suggestions.isEmpty {
                    Section {
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(suggestions) { item in
                                    Button {
                                        withAnimation { store.addToList(item) }
                                    } label: {
                                        Label(item.name, systemImage: "plus")
                                            .font(.subheadline)
                                    }
                                    .buttonStyle(.bordered)
                                    .buttonBorderShape(.capsule)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } header: {
                        Text("Azalan stoklardan")
                    }
                }

                if pending.isEmpty && inCart.isEmpty {
                    ContentUnavailableView(
                        "Liste boş", systemImage: "cart",
                        description: Text("“Hızlı ekle” ile ürün ekleyin. Evdeki herkes aynı listeyi görür."))
                }

                ForEach(groups, id: \.0) { category, entries in
                    Section(category) {
                        ForEach(entries) { entry in
                            ShoppingRow(entry: entry)
                        }
                    }
                }

                if !inCart.isEmpty {
                    Section {
                        ForEach(inCart) { entry in
                            ShoppingRow(entry: entry)
                        }
                    } header: {
                        Text("Sepette · \(inCart.count)")
                    }
                }
            }
            .navigationTitle("Alışveriş")
            .navigationSubtitle("\(pending.count) ürün · \(store.householdName)")
            .toolbar {
                if !inCart.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Bitir", systemImage: "checkmark") { isFinishPresented = true }
                            .labelStyle(.titleAndIcon)
                            .buttonStyle(.glassProminent)
                    }
                }
            }
            .sheet(isPresented: $isFinishPresented) {
                FinishShoppingSheet()
            }
            .onAppear {
                guard Demo.value("demo") == "finish", store.cartCount == 0 else { return }
                for entry in store.shopping.prefix(3) { store.toggleCart(entry) }
                isFinishPresented = true
            }
            .animation(.snappy, value: store.shopping)
        }
    }
}

private struct ShoppingRow: View {
    @Environment(PrototypeStore.self) private var store
    let entry: ShoppingEntry

    var body: some View {
        Button {
            withAnimation(.snappy) { store.toggleCart(entry) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: entry.isInCart ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(entry.isInCart ? Color.accentColor : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .strikethrough(entry.isInCart)
                        .foregroundStyle(entry.isInCart ? .secondary : .primary)
                    if !entry.quantity.isEmpty {
                        Text(entry.quantity)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                MemberAvatar(member: entry.addedBy)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(entry.name), \(entry.quantity), ekleyen \(entry.addedBy.name)")
        .accessibilityValue(entry.isInCart ? "Sepette" : "Alınacak")
        .sensoryFeedback(.selection, trigger: entry.isInCart)
        .swipeActions {
            Button("Sil", systemImage: "trash", role: .destructive) {
                withAnimation { store.remove(entry) }
            }
        }
    }
}

/// Closing the loop: bought items go to stock (opt-out per item), the receipt total becomes one
/// shared expense. Two decisions, one confirm.
struct FinishShoppingSheet: View {
    @Environment(PrototypeStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var addToStock: Set<ShoppingEntry.ID> = []
    @State private var total: Decimal?
    @State private var didAppear = false
    @FocusState private var isTotalFocused: Bool

    private var inCart: [ShoppingEntry] { store.shopping.filter(\.isInCart) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Fiş toplamı", value: $total, format: .currency(code: "TRY"))
                        .keyboardType(.decimalPad)
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                        .focused($isTotalFocused)
                } header: {
                    Text("Ne kadar ödendi?")
                } footer: {
                    Text("Ortak gider olarak “Market” kategorisine yazılır. Boş bırakabilirsiniz.")
                }

                Section {
                    ForEach(inCart) { entry in
                        Toggle(isOn: binding(for: entry)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.name)
                                Text(entry.linkedStockID == nil ? "Stokta takip edilmiyor" : "Stok +1")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(entry.linkedStockID == nil)
                    }
                } header: {
                    Text("Stoğa ekle")
                }
            }
            .navigationTitle("Alışverişi bitir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        store.finishShopping(addToStock: addToStock, total: total ?? 0)
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                }
            }
            .onAppear {
                guard !didAppear else { return }
                didAppear = true
                addToStock = Set(inCart.filter { $0.linkedStockID != nil }.map(\.id))
                isTotalFocused = true
            }
        }
    }

    private func binding(for entry: ShoppingEntry) -> Binding<Bool> {
        Binding(
            get: { addToStock.contains(entry.id) },
            set: { isOn in
                if isOn { addToStock.insert(entry.id) } else { addToStock.remove(entry.id) }
            })
    }
}
