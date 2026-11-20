import SwiftUI

/// "Ev": consumables you count (stock) and things you keep (belongings), one segmented switch.
struct HomeInventoryView: View {
    enum Mode: String, CaseIterable {
        case stock = "Stok"
        case belongings = "Eşyalar"
    }

    @Environment(PrototypeStore.self) private var store
    @State private var mode = Demo.value("demo") == "belongings" || Demo.value("demo") == "detail" ? Mode.belongings : Mode.stock
    @State private var path: [Belonging] = []
    @State private var query = ""

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    Picker("Görünüm", selection: $mode) {
                        ForEach(Mode.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }

                switch mode {
                case .stock: stockSections
                case .belongings: belongingSections
                }
            }
            .navigationTitle("Ev")
            .searchable(text: $query, prompt: mode == .stock ? "Stokta ara" : "Eşya ya da konum ara")
            .navigationDestination(for: Belonging.self) { BelongingDetailView(item: $0) }
            .onAppear {
                if Demo.value("demo") == "detail", path.isEmpty, let first = store.belongings.dropFirst().first {
                    path = [first]
                }
            }
        }
    }

    private func matches(_ text: String) -> Bool {
        text.matchesSearch(query)
    }

    @ViewBuilder
    private var stockSections: some View {
        let items = store.stock.filter { matches($0.name) || matches($0.place) }
        let places = Array(Set(items.map(\.place))).sorted()
        ForEach(places, id: \.self) { place in
            Section(place) {
                ForEach(items.filter { $0.place == place }) { item in
                    StockRow(item: item)
                }
            }
        }
    }

    @ViewBuilder
    private var belongingSections: some View {
        let items = store.belongings.filter { matches($0.name) || $0.path.contains(where: matches) }
        let rooms = Array(Set(items.map(\.room))).sorted()
        ForEach(rooms, id: \.self) { room in
            Section(room) {
                ForEach(items.filter { $0.room == room }) { item in
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
    }
}

private struct StockRow: View {
    @Environment(PrototypeStore.self) private var store
    let item: StockItem

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(symbol: item.symbol, tint: item.isLow ? Color("Warning") : .accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                HStack(spacing: 6) {
                    Text("\(item.quantity) \(item.unit)")
                        .monospacedDigit()
                    if item.isLow {
                        Text("Azaldı")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("Warning"))
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                stepButton("minus", delta: -1)
                    .disabled(item.quantity == 0)
                stepButton("plus", delta: 1)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func stepButton(_ symbol: String, delta: Int) -> some View {
        Button {
            withAnimation(.snappy) { store.adjust(item, by: delta) }
        } label: {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .accessibilityLabel(delta > 0 ? "\(item.name) bir artır" : "\(item.name) bir azalt")
        .sensoryFeedback(.increase, trigger: item.quantity)
    }
}

struct BelongingDetailView: View {
    let item: Belonging

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 44, weight: .regular))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 88, height: 88)
                        .background(Color.accentColor.opacity(0.12), in: .rect(cornerRadius: 22))
                        .accessibilityHidden(true)
                    Text(item.name)
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            Section("Nerede") {
                ForEach(Array(item.path.enumerated()), id: \.offset) { index, step in
                    Label(step, systemImage: index == item.path.count - 1 ? "mappin.circle.fill" : "arrow.turn.down.right")
                        .foregroundStyle(index == item.path.count - 1 ? Color.primary : Color.secondary)
                        .padding(.leading, CGFloat(index) * 14)
                }
            }

            if let ends = item.warrantyEnds {
                Section("Garanti") {
                    LabeledContent("Bitiş", value: ends.formatted(date: .long, time: .omitted))
                    let days = Calendar.current.dateComponents([.day], from: .now, to: ends).day ?? 0
                    LabeledContent("Kalan") {
                        Text("\(days) gün")
                            .monospacedDigit()
                            .foregroundStyle(days <= 31 ? Color("Warning") : .secondary)
                    }
                }
            }

            Section("Satın alma") {
                LabeledContent("Tarih", value: item.purchased.formatted(date: .abbreviated, time: .omitted))
                if item.price > 0 {
                    LabeledContent("Fiyat", value: item.price.lira)
                }
                LabeledContent("Mağaza", value: item.store)
            }

            if let maintenance = item.maintenance {
                Section("Bakım") {
                    Label(maintenance, systemImage: "wrench.adjustable")
                }
            }

            Section("Belgeler") {
                if item.documents.isEmpty {
                    Button("Fatura ya da garanti belgesi ekle", systemImage: "doc.badge.plus") {}
                } else {
                    ForEach(item.documents, id: \.self) { document in
                        Label(document, systemImage: "doc.text")
                    }
                }
            }
        }
        .navigationTitle(item.room)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Düzenle") {}
            }
        }
    }
}
