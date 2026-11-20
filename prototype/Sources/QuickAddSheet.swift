import SwiftUI

/// One entry point for the three things people log most. Expense is first and remembered;
/// the amount leads, everything else has a smart default, and the add button sits where the
/// thumb is (bottom), not in the top corner.
struct QuickAddSheet: View {
    enum Kind: String, CaseIterable {
        case expense = "Harcama"
        case shopping = "Alışveriş"
        case stock = "Stok"
    }

    @Environment(PrototypeStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("quickAdd.lastKind") private var lastKind = Kind.expense.rawValue
    @State private var kind = Kind.expense
    @State private var name = ""
    @State private var amount: Decimal?
    @State private var category = "Market"
    @State private var merchant = ""
    @State private var payer: Member?
    @State private var visibility = Visibility.household
    @State private var date = Date.now
    @State private var installmentCount = 1
    @State private var isRefund = false
    @State private var cardLast4: String?
    @State private var parsedFromMessage = false
    @State private var messageNotRecognized = false
    @FocusState private var isAmountFocused: Bool

    private var canSave: Bool {
        switch kind {
        case .shopping: !name.trimmingCharacters(in: .whitespaces).isEmpty
        case .expense: (amount ?? 0) > 0
        case .stock: false
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
                case .expense: expenseSections
                case .shopping:
                    Section {
                        TextField("Ne alınacak?", text: $name)
                            .submitLabel(.done)
                    } footer: {
                        Text("Listeye eklenir; evdeki herkes görür.")
                    }
                case .stock:
                    Section("Hızlıca düş") {
                        ForEach(store.stock.prefix(6)) { item in
                            HStack {
                                Text(item.name)
                                Spacer()
                                Text("\(item.quantity) \(item.unit)")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                Button("−1") { withAnimation { store.adjust(item, by: -1) } }
                                    .buttonStyle(.bordered)
                                    .disabled(item.quantity == 0)
                                    .accessibilityLabel("\(item.name) bir azalt")
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
            }
            .safeAreaInset(edge: .bottom) {
                if kind != .stock {
                    Button(action: save) {
                        Text(saveTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .disabled(!canSave)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .onAppear {
                kind = Kind(rawValue: lastKind) ?? .expense
                payer = store.me
                isAmountFocused = kind == .expense
                if Demo.value("sms") == "1" { apply(BankMessageParser.sample) }
            }
            .onChange(of: kind) { lastKind = kind.rawValue }
        }
    }

    private var saveTitle: String {
        guard kind == .expense, let amount, amount > 0 else { return "Ekle" }
        return "\(amount.lira) \(isRefund ? "iade " : "")ekle"
    }

    // MARK: Expense

    @ViewBuilder
    private var expenseSections: some View {
        Section {
            TextField("₺0", value: $amount, format: .currency(code: "TRY"))
                .keyboardType(.decimalPad)
                .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .focused($isAmountFocused)
                .accessibilityLabel("Tutar")
            HStack(spacing: 8) {
                ForEach(store.quickAmounts, id: \.self) { preset in
                    Button(preset.formatted(.currency(code: "TRY").precision(.fractionLength(0)))) {
                        amount = preset
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .frame(maxWidth: .infinity)
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        }

        Section("Kategori") {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(store.categories) { item in
                        let isOn = category == item.name
                        Button {
                            category = item.name
                        } label: {
                            Label(item.name, systemImage: item.symbol)
                                .font(.subheadline.weight(isOn ? .semibold : .regular))
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .tint(isOn ? item.color : .secondary)
                        .accessibilityAddTraits(isOn ? .isSelected : [])
                    }
                }
            }
            .scrollIndicators(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }

        if !store.recentMerchants.isEmpty {
            Section("Son harcamalar") {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(store.recentMerchants, id: \.title) { recent in
                            Button {
                                merchant = recent.title
                                category = recent.category
                                amount = recent.amount
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(recent.title).font(.subheadline.weight(.medium))
                                    Text(recent.amount.lira).font(.caption).monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }

        Section {
            TextField("İşyeri (isteğe bağlı)", text: $merchant)
            Picker("Ödeyen", selection: $payer) {
                ForEach(store.adults) { member in
                    Text(member == store.me ? "\(member.name) (ben)" : member.name).tag(Optional(member))
                }
            }
            Picker("Görünürlük", selection: $visibility) {
                ForEach(Visibility.allCases, id: \.self) { item in
                    Label(item.rawValue, systemImage: item.symbol).tag(item)
                }
            }
            DatePicker("Tarih", selection: $date, in: ...Date.now, displayedComponents: .date)
            Picker("Taksit", selection: $installmentCount) {
                Text("Tek çekim").tag(1)
                ForEach([2, 3, 6, 9, 12], id: \.self) { Text("\($0) taksit").tag($0) }
            }
        } footer: {
            Text(expenseFooter)
        }

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
                Label(
                    "Yapıştırılan metinde harcama tutarı bulunamadı. Doğrulama kodu ve reklam mesajları okunmaz; bankanın harcama mesajını kopyalayın ya da tutarı elle girin.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundStyle(Color("Warning"))
            } else {
                Text(parsedFromMessage
                    ? "Mesaj telefonunuzda okundu, hiçbir yere gönderilmedi\(cardLast4.map { ". Kart •••• \($0)" } ?? ""). Bilgileri kontrol edip ekleyin."
                    : "Bankanın harcama mesajını kopyalayıp yapıştırın: tutar, işyeri, tarih, kategori ve taksit kendiliğinden dolar.")
            }
        }
    }

    private var expenseFooter: String {
        var parts = [visibility.explanation]
        if installmentCount > 1, let amount, amount > 0 {
            let monthly = (amount / Decimal(installmentCount)).formatted(.currency(code: "TRY").precision(.fractionLength(0...2)))
            parts.append("Bu dönem bütçeye yalnızca ilk taksit (\(monthly)) yazılır; kalanı her ay düşer.")
        }
        if isRefund { parts.append("Bu bir iade: ilgili kategoriden düşülür.") }
        return parts.joined(separator: " ")
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
            if let guessed = result.category, store.categories.contains(where: { $0.name == guessed }) {
                category = guessed
            }
            if let parsedDate = result.date { date = min(parsedDate, .now) }
            installmentCount = result.installmentCount ?? 1
            isRefund = result.isRefund
            cardLast4 = result.cardLast4
            parsedFromMessage = true
        }
    }

    private func save() {
        switch kind {
        case .shopping:
            store.addToList(name: name)
        case .expense:
            let total = (amount ?? 0) * (isRefund ? -1 : 1)
            let title = merchant.isEmpty ? category : merchant
            let share = installmentCount > 1 ? total / Decimal(installmentCount) : total
            if installmentCount > 1 {
                store.installments.append(
                    Installment(
                        title: title, card: cardLast4.map { "Kart •••• \($0)" } ?? "Kart", category: category,
                        monthly: share, paidCount: 1, totalCount: installmentCount))
            }
            store.addExpense(title: title, amount: share, category: category, visibility: visibility, paidBy: payer, date: date)
        case .stock:
            break
        }
        dismiss()
    }
}
