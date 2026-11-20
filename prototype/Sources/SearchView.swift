import SwiftUI

/// One search across the home: belongings (with where they are), stock, the list and spending.
struct SearchView: View {
    @Environment(PrototypeStore.self) private var store
    @State private var query = Demo.value("query") ?? ""

    private func matches(_ text: String) -> Bool { text.matchesSearch(query) }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty && !store.recentSearches.isEmpty {
                    Section {
                        ForEach(store.recentSearches, id: \.self) { recent in
                            Button {
                                query = recent
                            } label: {
                                Label(recent, systemImage: "clock.arrow.circlepath")
                            }
                            .foregroundStyle(.primary)
                        }
                    } header: {
                        HStack {
                            Text("Son aramalar")
                            Spacer()
                            Button("Temizle") { withAnimation { store.recentSearches.removeAll() } }
                                .font(.subheadline)
                                .textCase(nil)
                        }
                    }
                }
                if query.isEmpty {
                    Section("Önerilen") {
                        ForEach(["HDMI kablo", "Garanti", "Pil", "Fatura"], id: \.self) { suggestion in
                            Button {
                                query = suggestion
                            } label: {
                                Label(suggestion, systemImage: "magnifyingglass")
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                } else {
                    results
                }
            }
            .navigationTitle("Ara")
            .searchable(text: $query, prompt: "Eşya, stok, harcama…")
            .onSubmit(of: .search) { store.remember(search: query) }
            .navigationDestination(for: Belonging.self) { BelongingDetailView(item: $0) }
        }
    }

    @ViewBuilder
    private var results: some View {
        let belongings = store.belongings.filter {
            matches($0.name) || $0.path.contains(where: matches) || ("garanti".matchesSearch(query) && $0.warrantyEnds != nil)
        }
        let stock = store.stock.filter { matches($0.name) }
        let list = store.shopping.filter { matches($0.name) }
        let expenses = store.expenses.filter { matches($0.title) || matches($0.category) }

        if belongings.isEmpty && stock.isEmpty && list.isEmpty && expenses.isEmpty {
            ContentUnavailableView.search(text: query)
        }
        if !belongings.isEmpty {
            Section("Eşyalar") {
                ForEach(belongings) { item in
                    NavigationLink(value: item) {
                        HStack(spacing: 12) {
                            IconBadge(symbol: item.symbol, tint: .accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                Text(item.path.joined(separator: " › "))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        if !stock.isEmpty {
            Section("Stok") {
                ForEach(stock) { item in
                    LabeledContent(item.name, value: "\(item.quantity) \(item.unit) · \(item.place)")
                }
            }
        }
        if !list.isEmpty {
            Section("Alışveriş listesi") {
                ForEach(list) { entry in
                    LabeledContent(entry.name, value: entry.isInCart ? "Sepette" : "Alınacak")
                }
            }
        }
        if !expenses.isEmpty {
            Section("Harcamalar") {
                ForEach(expenses) { expense in
                    LabeledContent(expense.title, value: expense.amount.lira)
                }
            }
        }
    }
}
