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
    @State private var kind = Demo.value("kind") == "expense" ? Kind.expense : Kind.shopping
    @State private var name = ""
    @State private var amount: Decimal?
    @State private var category = "Market"
    @State private var isPersonal = false
    @State private var merchant = ""
    @State private var installmentCount = 1
    @State private var parsedFromMessage = false
    @State private var messageNotRecognized = false
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
                        PasteButton(payloadType: String.self) { strings in
                            guard let message = strings.first else { return }
                            Task { @MainActor in apply(message) }
                        }
                        .labelStyle(.titleAndIcon)
                        .buttonBorderShape(.capsule)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    } header: {
                        Text("Banka mesajından")
                    } footer: {
                        if messageNotRecognized {
                            Label("Yapıştırılan metinde harcama tutarı bulunamadı. Bankanın harcama mesajını kopyaladığınızdan emin olun ya da tutarı elle girin.", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color("Warning"))
                        } else {
                            Text(parsedFromMessage
                                ? "Banka mesajı telefonunuzda okundu, hiçbir yere gönderilmedi. Bilgileri kontrol edip ekleyin."
                                : "Bankadan gelen harcama mesajını kopyalayıp yapıştırın: tutar, işyeri ve kategori kendiliğinden dolar.")
                        }
                    }
                    Section {
                        TextField("₺0", value: $amount, format: .currency(code: "TRY"))
                            .keyboardType(.decimalPad)
                            .font(.largeTitle.weight(.semibold))
                            .monospacedDigit()
                            .multilineTextAlignment(.center)
                            .focused($isFocused)
                            .accessibilityLabel("Tutar")
                        // Common amounts, one tap (Revolut's quick amounts).
                        HStack(spacing: 8) {
                            ForEach([50, 100, 250, 500], id: \.self) { preset in
                                Button("₺\(preset)") { amount = Decimal(preset) }
                                    .buttonStyle(.bordered)
                                    .buttonBorderShape(.capsule)
                                    .frame(maxWidth: .infinity)
                                    .accessibilityLabel("\(preset) lira")
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        TextField("İşyeri (isteğe bağlı)", text: $merchant)
                        Picker("Kategori", selection: $category) {
                            ForEach(expenseCategories, id: \.self) { Text($0) }
                        }
                        Picker("Taksit", selection: $installmentCount) {
                            Text("Tek çekim").tag(1)
                            ForEach([2, 3, 6, 9, 12], id: \.self) { Text("\($0) taksit").tag($0) }
                        }
                        Toggle(isOn: $isPersonal) {
                            Label("Kişisel", systemImage: "lock")
                        }
                    } footer: {
                        Text(expenseFooter)
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
            .onAppear {
                isFocused = true
                if Demo.value("sms") == "1" { apply(BankMessageParser.sample) }
            }
            .onChange(of: kind) { isFocused = kind != .stock }
        }
    }

    private var expenseFooter: String {
        let scope = isPersonal ? "Yalnızca siz görürsünüz." : "Ortak bütçeye yazılır."
        guard installmentCount > 1, let amount, amount > 0 else { return scope }
        let monthly = (amount / Decimal(installmentCount)).formatted(.currency(code: "TRY").precision(.fractionLength(0...2)))
        return "\(scope) Bu ay bütçeye yalnızca ilk taksit (\(monthly)) yazılır; kalanı her ay düşer."
    }

    private func apply(_ message: String) {
        guard let result = BankMessageParser.parse(message) else {
            // Tell the user instead of silently ignoring the paste.
            withAnimation {
                messageNotRecognized = true
                parsedFromMessage = false
            }
            return
        }
        withAnimation {
            messageNotRecognized = false
            amount = result.amount
            merchant = result.merchant ?? ""
            if let guessed = result.category, expenseCategories.contains(guessed) { category = guessed }
            parsedFromMessage = true
        }
    }

    private func save() {
        switch kind {
        case .shopping: store.addToList(name: name)
        case .expense:
            let total = amount ?? 0
            let title = merchant.isEmpty ? category : merchant
            if installmentCount > 1 {
                store.installments.append(
                    Installment(title: title, card: "Kart", category: category, monthly: total / Decimal(installmentCount), paidCount: 1, totalCount: installmentCount))
                store.addExpense(title: title, amount: total / Decimal(installmentCount), category: category, isPersonal: isPersonal)
            } else {
                store.addExpense(title: title, amount: total, category: category, isPersonal: isPersonal)
            }
        case .stock: break
        }
        dismiss()
    }
}
