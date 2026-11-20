import SwiftUI

/// The finance area, in three parts: Özet answers "are we okay?", Hareketler lists every record
/// with filters, Planla holds every setting. Visibility (Ortak / Eşimle / Kişisel) is a filter,
/// not a separate screen.
struct BudgetView: View {
    enum Section: String, CaseIterable {
        case summary = "Özet"
        case transactions = "Hareketler"
        case plan = "Planla"
    }

    @Environment(PrototypeStore.self) private var store
    @State private var section: Section = {
        switch Demo.value("budget") {
        case "transactions": .transactions
        case "plan": .plan
        default: .summary
        }
    }()
    /// Prototype walkthrough only: `-page installments|subscriptions|statements|stats|settle`.
    @State private var demoPage = Demo.value("page")

    var body: some View {
        NavigationStack {
            Group {
                switch section {
                case .summary: BudgetSummaryList()
                case .transactions: TransactionsList()
                case .plan: PlanList()
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Picker("Bölüm", selection: $section) {
                    ForEach(Section.allCases, id: \.self) { Text($0.rawValue) }
                }
                .contentSwitcherStyle()
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("Bütçe")
            .navigationSubtitle(periodTitle)
            .toolbar { QuickAddToolbarItem(store: store) }
            .navigationDestination(item: $demoPage) { page in
                switch page {
                case "installments": InstallmentsView()
                case "subscriptions": SubscriptionsView()
                case "statements": StatementsView()
                case "settle": SettlementView()
                default: StatisticsView()
                }
            }
        }
    }

    /// The current payday cycle, e.g. "15 Kas – 1 Ara".
    private var periodTitle: String {
        let end = store.safeToSpend.nextIncomeDate
        let start = store.lastIncomeDate
        let style = Date.FormatStyle.dateTime.day().month(.abbreviated)
        return "\(start.formatted(style)) – \(end.formatted(style))"
    }
}

// MARK: - Özet

private struct BudgetSummaryList: View {
    @Environment(PrototypeStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        List {
            Section {
                SafeToSpendHero()
            }

            Section {
                summary
                    .moneyPrivacy(store.hidesAmounts)
            } footer: {
                Text(changeText)
            }

            if let settlement = store.settlement {
                Section {
                    NavigationLink { SettlementView() } label: {
                        HStack(spacing: 12) {
                            IconBadge(symbol: "arrow.left.arrow.right", tint: .accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Hesaplaşma")
                                // Phrased without suffixes after names: Turkish vowel harmony makes "X'e/X'a" unsafe to generate.
                                Text("\(settlement.from.name) ödeyecek, \(settlement.to.name) alacak")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 8)
                            Text(settlement.amount.lira)
                                .monospacedDigit()
                                .moneyPrivacy(store.hidesAmounts)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }

            Section {
                ForEach(riskiest) { CategoryRow(category: $0) }
                NavigationLink("Tüm kategoriler") { CategoriesView() }
            } header: {
                Text("Dikkat isteyen kategoriler")
            }

            Section("Ödemeler") {
                if let next = store.statements.min(by: { $0.due < $1.due }) {
                    NavigationLink { StatementsView() } label: {
                        FinanceRow(
                            symbol: "creditcard", title: "Kart ekstreleri",
                            detail: "\(next.bank) son ödeme \(next.due.formatted(.relative(presentation: .named)))",
                            amount: next.amount)
                    }
                }
                NavigationLink { InstallmentsView() } label: {
                    FinanceRow(
                        symbol: "square.stack.3d.up", title: "Taksitler",
                        detail: "\(store.installments.count) aktif · bu ay ödenecek",
                        amount: store.installmentsThisMonth)
                }
                NavigationLink { SubscriptionsView() } label: {
                    FinanceRow(
                        symbol: "arrow.triangle.2.circlepath", title: "Abonelikler",
                        detail: "\(store.subscriptions.count) düzenli ödeme, faturalar dahil",
                        amount: store.subscriptionsMonthly)
                }
            }

            Section("Birikim hedefleri") {
                ForEach(store.goals) { GoalRow(goal: $0) }
            }

            Section {
                NavigationLink { StatisticsView() } label: {
                    Label("İstatistikler", systemImage: "chart.bar.xaxis")
                }
            }
        }
        .listSectionSpacing(.compact)
    }

    private var riskiest: [BudgetCategory] {
        Array(store.categories.sorted { $0.ratio > $1.ratio }.prefix(3))
    }

    private var changeText: String {
        guard let change = store.changeFromSamePeriod else {
            return "Geçen ayla kıyas, ilk ay tamamlanınca görünür."
        }
        let day = Calendar.current.component(.day, from: .now)
        let percent = abs(change).formatted(.percent.precision(.fractionLength(0)))
        let direction = change <= 0 ? "az" : "fazla"
        return "Geçen ayın ilk \(day) gününe göre \(percent) \(direction) harcandı. Bu dönem ortak gelir: \(store.monthlyIncome.lira)."
    }

    @ViewBuilder
    private var summary: some View {
        let remaining = store.monthlyBudget - store.spentThisMonth
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                LabeledContent("Esnek bütçe", value: store.monthlyBudget.lira)
                LabeledContent("Harcanan", value: store.spentThisMonth.lira)
                LabeledContent("Kalan", value: remaining.lira)
            }
            .monospacedDigit()
        } else {
            HStack(spacing: 0) {
                figure("Esnek bütçe", store.monthlyBudget, tint: .primary)
                Divider()
                figure("Harcanan", store.spentThisMonth, tint: .primary)
                Divider()
                figure("Kalan", remaining, tint: Color.accentColor)
            }
            .padding(.vertical, 6)
        }
    }

    private func figure(_ title: String, _ amount: Decimal, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(tint)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Hareketler

private struct TransactionsList: View {
    @Environment(PrototypeStore.self) private var store
    @State private var scope: Visibility?
    @State private var payer: Member?
    @State private var query = ""

    private var filtered: [Expense] {
        store.expenses.filter { expense in
            (scope == nil || expense.visibility == scope)
                && (payer == nil || expense.paidBy == payer)
                && (query.isEmpty || expense.title.matchesSearch(query) || expense.category.matchesSearch(query))
                // Someone else's personal records are never shown (ADR-0009).
                && (expense.visibility != .personal || expense.paidBy == store.me)
        }
    }

    private var days: [(Date, [Expense])] {
        Dictionary(grouping: filtered) { Calendar.current.startOfDay(for: $0.date) }
            .sorted { $0.key > $1.key }
            .map { ($0.key, $0.value) }
    }

    var body: some View {
        List {
            Section {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        FilterChip(title: "Tümü", isOn: scope == nil) { scope = nil }
                        ForEach(Visibility.allCases, id: \.self) { visibility in
                            FilterChip(title: visibility.rawValue, symbol: visibility.symbol, isOn: scope == visibility) {
                                scope = scope == visibility ? nil : visibility
                            }
                        }
                        Menu {
                            Button("Herkes") { payer = nil }
                            ForEach(store.adults) { member in
                                Button(member.name) { payer = member }
                            }
                        } label: {
                            Label(payer?.name ?? "Ödeyen", systemImage: "person.crop.circle")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                    }
                }
                .scrollIndicators(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            }

            if filtered.isEmpty {
                ContentUnavailableView(
                    "Kayıt yok", systemImage: "tray",
                    description: Text("Filtreleri değiştirin ya da sağ üstteki + ile harcama ekleyin."))
            }

            ForEach(days, id: \.0) { day, expenses in
                Section {
                    ForEach(expenses) { expense in
                        ExpenseRow(expense: expense)
                            .swipeActions {
                                Button("Kişisel", systemImage: "lock") {}
                                    .tint(.gray)
                                Button("Böl", systemImage: "square.split.2x1") {}
                                    .tint(Color.accentColor)
                            }
                    }
                } header: {
                    HStack {
                        Text(day.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        Spacer()
                        Text(expenses.reduce(Decimal(0)) { $0 + $1.amount }.lira)
                            .monospacedDigit()
                            .moneyPrivacy(store.hidesAmounts)
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "İşyeri ya da kategori")
    }
}

struct FilterChip: View {
    let title: String
    var symbol: String?
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let symbol {
                    Label(title, systemImage: symbol)
                } else {
                    Text(title)
                }
            }
            .font(.subheadline.weight(isOn ? .semibold : .regular))
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(isOn ? Color.accentColor : .secondary)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

// MARK: - Shared rows

struct CategoryRow: View {
    @Environment(PrototypeStore.self) private var store
    let category: BudgetCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label {
                    Text(category.name)
                } icon: {
                    Image(systemName: category.symbol)
                        .foregroundStyle(category.color)
                }
                Spacer()
                Text("\(category.spent.lira) / \(category.limit.lira)")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(category.ratio > 1 ? Color("Warning") : .secondary)
                    .moneyPrivacy(store.hidesAmounts)
            }
            BudgetMeter(ratio: category.ratio, tint: category.color)
            if category.ratio > 1 {
                Label("Limit \((category.spent - category.limit).lira) aşıldı", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(Color("Warning"))
                    .moneyPrivacy(store.hidesAmounts)
            } else if category.isNearLimit {
                Label("Limitin %80'i geçildi", systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(Color("Warning"))
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

/// One progress language for categories, instalments and goals: the fill, plus a tick for
/// where spending should be today if it were spread evenly over the period.
struct BudgetMeter: View {
    @Environment(PrototypeStore.self) private var store
    let ratio: Double
    var tint: Color = .accentColor
    var showsPace = true

    private var pace: Double {
        let today = Double(Calendar.current.component(.day, from: .now))
        return min(1, today / max(1, today + Double(store.remainingDays)))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.15))
                Capsule()
                    .fill(ratio > 1 ? Color("Warning") : tint)
                    .frame(width: proxy.size.width * min(1, max(0, ratio)))
                if showsPace {
                    Rectangle()
                        .fill(Color.primary.opacity(0.5))
                        .frame(width: 2, height: 10)
                        .offset(x: proxy.size.width * pace - 1)
                }
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}

struct ExpenseRow: View {
    @Environment(PrototypeStore.self) private var store
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            MemberAvatar(member: expense.paidBy)
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                HStack(spacing: 4) {
                    if expense.visibility != .household {
                        Image(systemName: expense.visibility.symbol)
                            .accessibilityLabel(expense.visibility.rawValue)
                    }
                    Text("\(expense.category) · \(expense.paidBy.name) ödedi")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text("−\(expense.amount.lira)")
                .monospacedDigit()
                .moneyPrivacy(store.hidesAmounts)
        }
        .accessibilityElement(children: .combine)
    }
}
