import SwiftUI

/// One entry point for the three things people log most. Each asks only what is essential.
struct QuickAddSheet: View {
    enum Kind: String, CaseIterable {
        case shopping = "Alışveriş"
        case expense = "Harcama"
        case stock = "Stok"
    }

    @Environment(PrototypeStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var kind = Kind.shopping
    @State private var name = ""
    @State private var amount: Decimal?
    @State private var category = "Market"
    @State private var isPersonal = false
    @FocusState private var isFocused: Bool

    private let expenseCategories = ["Market", "Faturalar", "Ulaşım", "Eğlence", "Sağlık", "Ev"]

    private var canSave: Bool {
        switch kind {
        case .shopping: !name.trimmingCharacters(in: .whitespaces).isEmpty
        case .expense: (amount ?? 0) > 0
        case .stock: true
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Tür", selection: $kind) {
                        ForEach(Kind.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .contentSwitcherStyle()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }

                switch kind {
                case .shopping:
                    Section {
                        TextField("Ne alınacak?", text: $name)
                            .focused($isFocused)
                            .submitLabel(.done)
                    } footer: {
                        Text("Listeye eklenir; evdeki herkes görür.")
                    }
                case .expense:
                    Section {
                        TextField("Tutar", value: $amount, format: .currency(code: "TRY"))
                            .keyboardType(.decimalPad)
                            .font(.title2.weight(.semibold))
                            .monospacedDigit()
                            .focused($isFocused)
                        Picker("Kategori", selection: $category) {
                            ForEach(expenseCategories, id: \.self) { Text($0) }
                        }
                        Toggle(isOn: $isPersonal) {
                            Label("Kişisel", systemImage: "lock")
                        }
                    } footer: {
                        Text(isPersonal ? "Yalnızca siz görürsünüz." : "Ortak bütçeye yazılır.")
                    }
                case .stock:
                    Section("Hızlıca düş") {
                        ForEach(store.stock.prefix(5)) { item in
                            HStack {
                                Text(item.name)
                                Spacer()
                                Text("\(item.quantity) \(item.unit)")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                Button("−1") { withAnimation { store.adjust(item, by: -1) } }
                                    .buttonStyle(.bordered)
                                    .disabled(item.quantity == 0)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Hızlı ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç", role: .cancel) { dismiss() }
                }
                if kind != .stock {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Ekle", action: save)
                            .buttonStyle(.glassProminent)
                            .disabled(!canSave)
                    }
                }
            }
            .onAppear { isFocused = true }
            .onChange(of: kind) { isFocused = kind != .stock }
        }
    }

    private func save() {
        switch kind {
        case .shopping: store.addToList(name: name)
        case .expense:
            store.addExpense(title: category, amount: amount ?? 0, category: category, isPersonal: isPersonal)
        case .stock: break
        }
        dismiss()
    }
}
