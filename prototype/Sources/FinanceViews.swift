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

struct SubscriptionsView: View {
    @Environment(PrototypeStore.self) private var store

    var body: some View {
        List {
            Section {
                LabeledContent("Her ay toplam", value: store.subscriptionsMonthly.lira)
                    .monospacedDigit()
                    .moneyPrivacy(store.hidesAmounts)
                LabeledContent("Yılda", value: (store.subscriptionsMonthly * 12).lira)
                    .monospacedDigit()
                    .moneyPrivacy(store.hidesAmounts)
            }
            Section {
                ForEach(store.subscriptions.sorted { $0.day < $1.day }) { subscription in
                    HStack(spacing: 12) {
                        IconBadge(symbol: subscription.symbol, tint: .accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(subscription.name)
                            Text("Her ay \(subscription.day). gün")
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
            } header: {
                Text("Düzenli ödemeler")
            } footer: {
                Text("Günü gelince hatırlatılır. İsterseniz ödendi olarak kendiliğinden gidere yazılır.")
            }
        }
        .navigationTitle("Abonelik ve faturalar")
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

struct CategoriesView: View {
    @Environment(PrototypeStore.self) private var store

    var body: some View {
        List {
            Section {
                ForEach(store.categories) { CategoryRow(category: $0) }
            } footer: {
                Text("Çubuktaki ince çizgi, harcama dönem boyunca eşit dağılsaydı bugün nerede olunacağını gösterir. Limitin %80'inde ve aşıldığında bildirim gelir.")
            }
        }
        .navigationTitle("Kategoriler")
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
