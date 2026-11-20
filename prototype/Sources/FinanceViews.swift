import Charts
import SwiftUI

// Finance building blocks for the Bütçe tab: the payday number, payments (card statements,
// instalments, subscriptions), shared savings goals and statistics. Content layer only.

/// "Güvenle harcanabilir": cash minus everything due before the next income, per day.
/// Every deduction is one tap away, so the number is never a black box (FR-016).
struct SafeToSpendHero: View {
    @Environment(PrototypeStore.self) private var store
    @State private var isBreakdownPresented = false

    var body: some View {
        let safe = store.safeToSpend
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(incomeLine(safe))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    isBreakdownPresented = true
                } label: {
                    Label("Nasıl hesaplandı?", systemImage: "info.circle")
                        .labelStyle(.iconOnly)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.borderless)
            }
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 6) { amount(safe); perDay }
                VStack(alignment: .leading, spacing: 0) { amount(safe); perDay }
            }
            Text("Yaklaşan ödemeler düşüldü: \(safe.deductions.reduce(Decimal(0)) { $0 + $1.amount }.lira)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .moneyPrivacy(store.hidesAmounts)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $isBreakdownPresented) {
            SafeToSpendBreakdown()
                .presentationDetents([.medium, .large])
        }
    }

    private func incomeLine(_ safe: SafeToSpend) -> String {
        let who = safe.nextIncome.map { " · \($0.member.name)" } ?? ""
        return "Sonraki maaş\(who) · \(safe.days) gün"
    }

    private func amount(_ safe: SafeToSpend) -> some View {
        Text(safe.perDay.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
            .font(.largeTitle.weight(.bold))
            .monospacedDigit()
            .contentTransition(.numericText())
            .lineLimit(1)
            .fixedSize()
            .moneyPrivacy(store.hidesAmounts)
    }

    private var perDay: some View {
        Text("günde güvenle harcanabilir")
            .font(.headline)
            .foregroundStyle(.secondary)
    }
}

/// The arithmetic behind the safe-to-spend number, line by line.
struct SafeToSpendBreakdown: View {
    @Environment(PrototypeStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let safe = store.safeToSpend
        NavigationStack {
            List {
                Section {
                    LabeledContent("Hesaplardaki para", value: safe.cash.lira)
                    ForEach(safe.deductions) { line in
                        LabeledContent(line.title, value: "−\(line.amount.lira)")
                    }
                    LabeledContent("Tampon", value: "−\(safe.buffer.lira)")
                } footer: {
                    Text("Kart harcamaları harcandığı anda sayıldığı için ekstre burada yalnızca nakit çıkışı olarak düşülür; bütçeye ikinci kez yazılmaz.")
                }
                .monospacedDigit()
                Section {
                    LabeledContent("Kullanılabilir", value: safe.available.lira)
                        .fontWeight(.semibold)
                    LabeledContent("Sonraki gelir", value: safe.nextIncomeDate.formatted(.dateTime.day().month(.wide).weekday(.wide)))
                    LabeledContent("Kalan gün", value: "\(safe.days)")
                    LabeledContent("Günde", value: safe.perDay.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                        .fontWeight(.semibold)
                } footer: {
                    Text("Maaş günü hafta sonuna denk gelirse bankanın ödediği önceki iş günü esas alınır. Tamponu ve maaş günlerini Planla'dan değiştirebilirsiniz.")
                }
                .monospacedDigit()
            }
            .moneyPrivacy(store.hidesAmounts)
            .navigationTitle("Nasıl hesaplandı?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
    }
}

struct FinanceRow: View {
    @Environment(PrototypeStore.self) private var store
    let symbol: String
    let title: String
    let detail: String
    let amount: Decimal

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(symbol: symbol, tint: .accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(amount.lira)
                .monospacedDigit()
                .moneyPrivacy(store.hidesAmounts)
        }
        .accessibilityElement(children: .combine)
    }
}

struct GoalRow: View {
    @Environment(PrototypeStore.self) private var store
    let goal: SavingsGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                IconBadge(symbol: goal.symbol, tint: Color("Mint"))
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                    Text("Hedef \(goal.deadline.formatted(.dateTime.month(.wide).year())) · ayda \(goal.monthlyNeeded.formatted(.currency(code: "TRY").precision(.fractionLength(0))))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .moneyPrivacy(store.hidesAmounts)
                }
                Spacer(minLength: 8)
                Text(goal.ratio, format: .percent.precision(.fractionLength(0)))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            ProgressView(value: goal.ratio)
                .tint(Color("Mint"))
            Text("\(goal.saved.lira) / \(goal.target.lira)")
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .moneyPrivacy(store.hidesAmounts)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Payments

struct StatementsView: View {
    @Environment(PrototypeStore.self) private var store

    var body: some View {
        List {
            Section {
                ForEach(store.statements.sorted { $0.due < $1.due }) { statement in
                    HStack(spacing: 12) {
                        IconBadge(symbol: "creditcard", tint: .accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(statement.bank)
                            Text("Son ödeme \(statement.due.formatted(.dateTime.day().month(.wide)))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Text(statement.amount.lira)
                            .monospacedDigit()
                            .moneyPrivacy(store.hidesAmounts)
                    }
                    .swipeActions {
                        Button("Ödendi", systemImage: "checkmark") {}
                            .tint(Color.accentColor)
                    }
                    .accessibilityElement(children: .combine)
                }
            } footer: {
                Text("Son ödeme gününden 3 gün önce ve aynı gün hatırlatılır. Ödendi olarak işaretlenince yaklaşanlardan düşer.")
            }
        }
        .navigationTitle("Kart ekstreleri")
    }
}

struct InstallmentsView: View {
    @Environment(PrototypeStore.self) private var store

    var body: some View {
        List {
            Section {
                LabeledContent("Bu ay ödenecek", value: store.installmentsThisMonth.lira)
                    .monospacedDigit()
                    .moneyPrivacy(store.hidesAmounts)
            } footer: {
                Text("Bütçeye her ay yalnızca o ayın taksiti yazılır; toplam tutar tek seferde düşmez.")
            }
            Section("Aktif taksitler") {
                ForEach(store.installments) { installment in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(installment.title)
                                Text("\(installment.card) · \(installment.category)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 8)
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(installment.monthly.lira) / ay")
                                    .monospacedDigit()
                                Text("\(installment.paidCount)/\(installment.totalCount) taksit")
                                    .font(.subheadline)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            .moneyPrivacy(store.hidesAmounts)
                        }
                        ProgressView(value: Double(installment.paidCount), total: Double(installment.totalCount))
                        Text("Kalan \(installment.remaining.lira)")
                            .font(.footnote)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .moneyPrivacy(store.hidesAmounts)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .navigationTitle("Taksitler")
    }
}

/// Subscriptions: count and yearly total up top, each row says when it renews; add from a
/// catalogue of common Turkish services or a custom one (Orbit / Subo patterns).
struct SubscriptionsView: View {
    @Environment(PrototypeStore.self) private var store
    @State private var showsYearly = false
    @State private var isAddPresented = false

    var body: some View {
        List {
            Section {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(store.subscriptions.count)")
                            .font(.largeTitle.weight(.bold))
                            .monospacedDigit()
                        Text("aktif ödeme")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text((showsYearly ? store.subscriptionsMonthly * 12 : store.subscriptionsMonthly).lira)
                            .font(.title2.weight(.semibold))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .moneyPrivacy(store.hidesAmounts)
                        Button(showsYearly ? "yılda ⌃" : "ayda ⌃") {
                            withAnimation { showsYearly.toggle() }
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(showsYearly ? "Yıllık gösteriliyor, aylığa geç" : "Aylık gösteriliyor, yıllığa geç")
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Sıradaki yenilemeler") {
                ForEach(store.subscriptions.sorted { $0.nextRenewal < $1.nextRenewal }) { subscription in
                    NavigationLink { SubscriptionDetail(subscription: subscription) } label: {
                        HStack(spacing: 12) {
                            IconBadge(symbol: subscription.symbol, tint: .accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(subscription.name)
                                Text(renewalText(subscription))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 8)
                            Text(subscription.amount.lira)
                                .monospacedDigit()
                                .moneyPrivacy(store.hidesAmounts)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .navigationTitle("Abonelikler")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Abonelik ekle", systemImage: "plus") { isAddPresented = true }
            }
        }
        .sheet(isPresented: $isAddPresented) {
            AddSubscriptionSheet()
        }
    }

    private func renewalText(_ subscription: Subscription) -> String {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: subscription.nextRenewal).day ?? 0
        let when = days <= 1 ? "Yarın" : "\(days) gün sonra"
        return "\(when) · \(subscription.nextRenewal.formatted(.dateTime.day().month(.wide)))"
    }
}

struct SubscriptionDetail: View {
    @Environment(PrototypeStore.self) private var store
    let subscription: Subscription
    @State private var isDeleteConfirming = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    IconBadge(symbol: subscription.symbol, tint: .accentColor)
                        .scaleEffect(1.4, anchor: .leading)
                        .padding(.bottom, 6)
                    Text(subscription.name)
                        .font(.title.weight(.bold))
                    Text("\(subscription.amount.lira) / ay")
                        .font(.title3)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .moneyPrivacy(store.hidesAmounts)
                }
                .padding(.vertical, 6)
            }
            Section {
                LabeledContent("Sonraki ödeme", value: subscription.nextRenewal.formatted(.dateTime.day().month(.wide).weekday(.wide)))
                LabeledContent("Ne zamandır", value: "\(subscription.monthsActive) ay")
                LabeledContent("Bugüne kadar", value: subscription.totalPaid.lira)
                    .moneyPrivacy(store.hidesAmounts)
                LabeledContent("Yılda", value: (subscription.amount * 12).lira)
                    .moneyPrivacy(store.hidesAmounts)
            }
            .monospacedDigit()
            Section {
                Button("Bu ay ödendi", systemImage: "checkmark.circle") {}
                Button("Aboneliği sil", systemImage: "trash", role: .destructive) { isDeleteConfirming = true }
                    .confirmationDialog("\(subscription.name) silinsin mi?", isPresented: $isDeleteConfirming, titleVisibility: .visible) {
                        Button("Sil", role: .destructive) {
                            store.subscriptions.removeAll { $0.id == subscription.id }
                            dismiss()
                        }
                    } message: {
                        Text("Geçmiş ödemeler harcamalarda kalır; yalnızca gelecekteki hatırlatmalar durur.")
                    }
            }
        }
        .navigationTitle(subscription.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Add from a catalogue of common services (search + group chips), or a custom one.
struct AddSubscriptionSheet: View {
    @Environment(PrototypeStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var group: String?
    @State private var selected: ServiceTemplate?
    @State private var amount: Decimal?
    @State private var day = Calendar.current.component(.day, from: .now)

    private var groups: [String] { Array(Set(ServiceTemplate.catalog.map(\.group))).sorted { $0.localizedStandardCompare($1) == .orderedAscending } }
    private var results: [ServiceTemplate] {
        ServiceTemplate.catalog.filter { template in
            (group == nil || template.group == group) && template.name.matchesSearch(query)
                && !store.subscriptions.contains { $0.name == template.name }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let selected {
                    Form {
                        Section {
                            Label(selected.name, systemImage: selected.symbol)
                                .font(.headline)
                            TextField("Tutar", value: $amount, format: .currency(code: "TRY"))
                                .keyboardType(.decimalPad)
                                .monospacedDigit()
                            Stepper("Her ay \(day). gün", value: $day, in: 1...31)
                        } footer: {
                            Text("Ödeme gününden önce hatırlatılır ve güvenle harcanabilir tutardan düşülür.")
                        }
                    }
                } else {
                    List {
                        Section {
                            ScrollView(.horizontal) {
                                HStack(spacing: 8) {
                                    FilterChip(title: "Tümü", isOn: group == nil) { group = nil }
                                    ForEach(groups, id: \.self) { name in
                                        FilterChip(title: name, isOn: group == name) { group = group == name ? nil : name }
                                    }
                                }
                            }
                            .scrollIndicators(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                        Section {
                            Button {
                                choose(ServiceTemplate(name: query.isEmpty ? "Yeni abonelik" : query, group: "Diğer", symbol: "plus.circle", typicalAmount: 0))
                            } label: {
                                Label(query.isEmpty ? "Özel abonelik" : "“\(query)” ekle", systemImage: "plus.circle.fill")
                            }
                        }
                        Section("Sık kullanılanlar") {
                            ForEach(results) { template in
                                Button { choose(template) } label: {
                                    HStack(spacing: 12) {
                                        IconBadge(symbol: template.symbol, tint: .accentColor)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(template.name).foregroundStyle(.primary)
                                            Text("\(template.group) · genelde \(template.typicalAmount.lira)")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .searchable(text: $query, prompt: "Servis ara")
                }
            }
            .navigationTitle(selected == nil ? "Abonelik ekle" : "Ayrıntılar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç", role: .cancel) { dismiss() }
                }
                if selected != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Ekle") { save() }
                            .buttonStyle(.glassProminent)
                            .disabled((amount ?? 0) <= 0)
                    }
                }
            }
        }
    }

    private func choose(_ template: ServiceTemplate) {
        withAnimation {
            selected = template
            amount = template.typicalAmount > 0 ? template.typicalAmount : nil
        }
    }

    private func save() {
        guard let selected, let amount, amount > 0 else { return }
        store.subscriptions.append(Subscription(name: selected.name, amount: amount, day: day, symbol: selected.symbol, since: .now))
        dismiss()
    }
}

// MARK: - Statistics

struct StatisticsView: View {
    @Environment(PrototypeStore.self) private var store

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Geçen ayın aynı dönemine göre")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    let change = store.changeFromSamePeriod ?? 0
                    Text(change, format: .percent.precision(.fractionLength(0)).sign(strategy: .always()))
                        .font(.largeTitle.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(change <= 0 ? Color.accentColor : Color("Warning"))
                    Text("Geçen ayın aynı günlerinde \(store.lastMonthSamePeriodSpent.lira), bu ay \(store.spentThisMonth.lira). Geçen ayın tamamı \(store.lastMonthSpent.lira).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .moneyPrivacy(store.hidesAmounts)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
            }

            Section("Son 6 ay") {
                Chart(store.monthlyHistory, id: \.month) { entry in
                    BarMark(x: .value("Ay", entry.month), y: .value("Harcama", entry.amount))
                        .foregroundStyle(entry.month == store.monthlyHistory.last?.month ? Color.accentColor : Color.accentColor.opacity(0.35))
                        .cornerRadius(4)
                        .annotation(position: .top) {
                            Text(entry.amount.thousandsLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                }
                .chartYAxis(.hidden)
                .frame(height: 170)
                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                .padding(.vertical, 6)
                .moneyPrivacy(store.hidesAmounts)
                .accessibilityLabel("Son altı ayın aylık harcaması")
            }

            Section("Bu ay nereye gitti") {
                let total = store.categories.reduce(Decimal(0)) { $0 + $1.spent }
                ForEach(store.categories.sorted { $0.spent > $1.spent }) { category in
                    let share = NSDecimalNumber(decimal: category.spent / total).doubleValue
                    HStack {
                        Label(category.name, systemImage: category.symbol)
                        Spacer()
                        Text(share, format: .percent.precision(.fractionLength(0)))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Text(category.spent.lira)
                            .monospacedDigit()
                            .frame(minWidth: 80, alignment: .trailing)
                            .moneyPrivacy(store.hidesAmounts)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .navigationTitle("İstatistikler")
    }
}


// MARK: - Settlement

/// Who paid what for shared spending this period, and the one transfer that evens it out.
struct SettlementView: View {
    @Environment(PrototypeStore.self) private var store
    @State private var isSettled = false

    var body: some View {
        List {
            if let settlement = store.settlement, !isSettled {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(settlement.from.name) → \(settlement.to.name)")
                            .font(.headline)
                        Text(settlement.amount.lira)
                            .font(.largeTitle.weight(.bold))
                            .monospacedDigit()
                            .moneyPrivacy(store.hidesAmounts)
                        Text("ödeyince bu dönemin ortak harcamaları eşitlenir.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    .accessibilityElement(children: .combine)
                    Button {
                        withAnimation { isSettled = true }
                    } label: {
                        Label("Hesaplaştık", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .listRowBackground(Color.clear)
                }
            } else {
                ContentUnavailableView(
                    "Hesaplar denk", systemImage: "checkmark.seal",
                    description: Text("Bu dönem kimse kimseye borçlu değil."))
            }

            Section {
                ForEach(store.balances) { balance in
                    HStack(spacing: 12) {
                        MemberAvatar(member: balance.member)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(balance.member.name)
                            Text("Payı %\(Int((store.share(of: balance.member) * 100).rounded())) · \(balance.owes.lira)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(balance.paid.lira) ödedi")
                                .monospacedDigit()
                            Text(balance.net >= 0 ? "+\(balance.net.lira)" : "−\((-balance.net).lira)")
                                .font(.subheadline)
                                .monospacedDigit()
                                .foregroundStyle(balance.net >= 0 ? Color.accentColor : Color("Warning"))
                        }
                    }
                    .moneyPrivacy(store.hidesAmounts)
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text("Bu dönem ortak harcamalar")
            } footer: {
                Text("Bölüşüm: \(store.splitRule.rawValue). Kişisel kayıtlar hesaba girmez. Bölüşümü Planla'dan değiştirebilirsiniz.")
            }
        }
        .navigationTitle("Hesaplaşma")
    }
}

// MARK: - Categories

/// Categories with limits; add from suggestions in one tap, edit colour/icon/limit, and delete
/// without losing spending (records move to "Diğer").
struct CategoriesView: View {
    @Environment(PrototypeStore.self) private var store
    @State private var editing: BudgetCategory?

    var body: some View {
        List {
            Section {
                ForEach(store.categories) { category in
                    Button { editing = category } label: { CategoryRow(category: category) }
                        .buttonStyle(.plain)
                }
            } footer: {
                Text("Çubuktaki ince çizgi, harcama dönem boyunca eşit dağılsaydı bugün nerede olunacağını gösterir. Limitin %80'inde ve aşıldığında bildirim gelir. Düzenlemek için dokunun.")
            }
            if !store.availableSuggestions.isEmpty {
                Section("Önerilen") {
                    ForEach(store.availableSuggestions, id: \.name) { suggestion in
                        HStack(spacing: 12) {
                            IconBadge(symbol: suggestion.symbol, tint: suggestion.color)
                            Text(suggestion.name)
                            Spacer()
                            Button {
                                withAnimation { store.addCategory(name: suggestion.name, symbol: suggestion.symbol, color: suggestion.color) }
                            } label: {
                                Label("\(suggestion.name) ekle", systemImage: "plus.circle.fill")
                                    .labelStyle(.iconOnly)
                                    .font(.title2)
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }
        }
        .navigationTitle("Kategoriler")
        .sheet(item: $editing) { category in
            CategoryEditor(category: category)
                .presentationDetents([.medium, .large])
        }
    }
}

struct CategoryEditor: View {
    @Environment(PrototypeStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let category: BudgetCategory
    @State private var limit: Decimal = 0
    @State private var symbol = ""
    @State private var color = Color.accentColor
    @State private var isDeleteConfirming = false

    private let symbols = ["cart", "bolt", "car", "popcorn", "cross.case", "sofa", "graduationcap", "figure.and.child.holdinghands", "house", "banknote", "pawprint", "tshirt", "heart", "fork.knife", "airplane", "gift"]
    private let colors: [Color] = [
        Color(red: 0.16, green: 0.55, blue: 0.42), Color(red: 0.16, green: 0.44, blue: 0.74), Color(red: 0.78, green: 0.45, blue: 0.12),
        Color(red: 0.52, green: 0.33, blue: 0.75), Color(red: 0.80, green: 0.25, blue: 0.30), Color(red: 0.50, green: 0.40, blue: 0.30),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Aylık limit") {
                    TextField("Limit", value: $limit, format: .currency(code: "TRY").precision(.fractionLength(0)))
                        .keyboardType(.numberPad)
                        .monospacedDigit()
                }
                Section("Simge") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(symbols, id: \.self) { name in
                            Button { symbol = name } label: {
                                Image(systemName: name)
                                    .frame(width: 44, height: 44)
                                    .background(symbol == name ? color.opacity(0.2) : Color.clear, in: .rect(cornerRadius: 10))
                                    .foregroundStyle(symbol == name ? color : .secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(name)
                            .accessibilityAddTraits(symbol == name ? .isSelected : [])
                        }
                    }
                }
                Section("Renk") {
                    HStack {
                        ForEach(Array(colors.enumerated()), id: \.offset) { _, option in
                            Button { color = option } label: {
                                Circle().fill(option)
                                    .frame(width: 32, height: 32)
                                    .overlay { if option == color { Image(systemName: "checkmark").foregroundStyle(.white) } }
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Section {
                    Button("Kategoriyi sil", role: .destructive) { isDeleteConfirming = true }
                        .confirmationDialog("\(category.name) silinsin mi?", isPresented: $isDeleteConfirming, titleVisibility: .visible) {
                            Button("Sil", role: .destructive) {
                                store.deleteCategory(category)
                                dismiss()
                            }
                        } message: {
                            Text("Bu kategorideki \(store.expenseCount(in: category)) harcama silinmez, “Diğer” kategorisine taşınır.")
                        }
                }
            }
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Vazgeç", role: .cancel) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        if let index = store.categories.firstIndex(where: { $0.id == category.id }) {
                            store.categories[index].limit = limit
                            store.categories[index].symbol = symbol
                            store.categories[index].color = color
                        }
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                }
            }
            .onAppear {
                limit = category.limit
                symbol = category.symbol
                color = category.color
            }
        }
    }
}

// MARK: - Planla

/// Every finance setting in one place, with smart defaults; advanced methods are folded away.
struct PlanList: View {
    @Environment(PrototypeStore.self) private var store
    @State private var showsAdvanced = false

    var body: some View {
        @Bindable var store = store
        List {
            Section {
                ForEach($store.incomes) { $income in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            MemberAvatar(member: income.member)
                            Text("\(income.member.name) · \(income.title)")
                            Spacer()
                            Text(income.amount.lira)
                                .monospacedDigit()
                                .moneyPrivacy(store.hidesAmounts)
                        }
                        Stepper(value: $income.day, in: 1...31) {
                            // "Her ay 15. gün": avoids generating the Turkish suffix after a number.
                            Text("Her ay \(income.day). gün")
                        }
                    }
                    .padding(.vertical, 2)
                }
                Button("Gelir ekle", systemImage: "plus") {}
            } header: {
                Text("Gelirler ve maaş günleri")
            } footer: {
                Text("Dönem en yakın maaş gününde biter. Hafta sonuna denk gelirse önceki iş günü esas alınır.")
            }

            Section {
                Picker("Yöntem", selection: $store.budgetMethod) {
                    ForEach(showsAdvanced ? BudgetMethod.allCases : [.payday, .monthly], id: \.self) {
                        Text($0.rawValue)
                    }
                }
                LabeledContent("Aylık esnek bütçe", value: store.monthlyBudget.lira)
                    .moneyPrivacy(store.hidesAmounts)
                Toggle("Gelişmiş yöntemleri göster", isOn: $showsAdvanced.animation())
            } header: {
                Text("Bütçe yöntemi")
            } footer: {
                Text(store.budgetMethod.explanation)
            }

            Section {
                Picker("Ortak giderler", selection: $store.splitRule) {
                    ForEach(SplitRule.allCases, id: \.self) { Text($0.rawValue) }
                }
                ForEach(store.adults) { member in
                    LabeledContent(member.name, value: (store.share(of: member)).formatted(.percent.precision(.fractionLength(0))))
                }
            } header: {
                Text("Bölüşüm")
            } footer: {
                Text("Hesaplaşma bu orana göre yapılır.")
            }

            Section {
                NavigationLink("Kategoriler ve limitler") { CategoriesView() }
                HStack(spacing: 8) {
                    ForEach(store.quickAmounts, id: \.self) { amount in
                        Text(amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                            .font(.subheadline)
                            .monospacedDigit()
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.12), in: .capsule)
                    }
                }
                Stepper(value: $store.safetyBuffer, in: 0...10_000, step: 250) {
                    LabeledContent("Tampon", value: store.safetyBuffer.lira)
                }
            } header: {
                Text("Kategoriler, hızlı tutarlar ve tampon")
            } footer: {
                Text("Hızlı tutarlar Hızlı ekle'de tek dokunuşla girilir. Tampon, maaştan önce sıfıra inmemek için güvenle harcanabilir tutardan ayrılır.")
            }

            Section {
                Toggle("Eşim harcama ekleyince", isOn: $store.notifyOnPartnerExpense)
                Toggle("Çocuklar harcama ekleyince", isOn: $store.notifyOnChildExpense)
                Toggle("Kategori limitinin %80'i ve aşımı", isOn: $store.notifyOnLimit)
                Toggle("Ödeme ve ekstre günü", isOn: $store.notifyOnPaymentDue)
            } header: {
                Text("Bildirimlerim")
            } footer: {
                Text("Bu ayarlar yalnızca sizin içindir; her üye kendi bildirimlerini seçer.")
            }
        }
        .listSectionSpacing(.compact)
    }
}
