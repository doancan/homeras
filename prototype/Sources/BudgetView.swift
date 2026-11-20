import Charts
import SwiftUI

/// Month at a glance. "Ortak" is the household's money; "Kişisel" is visible only to its owner.
struct BudgetView: View {
    enum Scope: String, CaseIterable {
        case shared = "Ortak"
        case personal = "Kişisel"
    }

    @Environment(PrototypeStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var scope = Demo.value("demo") == "personal" ? Scope.personal : Scope.shared
    /// Prototype walkthrough only: `-page installments|subscriptions|statements|stats`.
    @State private var demoPage = Demo.value("page")

    private var expenses: [Expense] {
        store.expenses.filter { $0.isPersonal == (scope == .personal) }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
            List {
                Section {
                    Picker("Kapsam", selection: $scope) {
                        ForEach(Scope.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .contentSwitcherStyle()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }

                switch scope {
                case .shared:
                    Section {
                        PaydayHero()
                    }
                    Section {
                        summary
                            .moneyPrivacy(store.hidesAmounts)
                    } footer: {
                        Text(changeText)
                    }
                    Section {
                        ForEach(store.categories) { CategoryRow(category: $0) }
                    } header: {
                        Text("Kategori limitleri")
                    } footer: {
                        Text("Bir kategori limitinin %80'ine gelince ve aşınca evdeki herkese bildirim gider.")
                    }
                    Section("Ödemeler") {
                        EmptyView().id("payments")
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
                    Section {
                        ForEach(store.goals) { GoalRow(goal: $0) }
                    } header: {
                        Text("Birikim hedefleri")
                    } footer: {
                        Text("Hedefe zamanında ulaşmak için her ay ayrılması gereken tutar hesaplanır.")
                    }
                    Section {
                        NavigationLink { StatisticsView() } label: {
                            Label("İstatistikler", systemImage: "chart.bar.xaxis")
                        }
                    }
                case .personal:
                    Section {
                        LabeledContent("Bu ay kişisel", value: expenses.reduce(Decimal(0)) { $0 + $1.amount }.lira)
                            .monospacedDigit()
                        Label {
                            Text("Kişisel harcamalarınızı yalnızca siz görürsünüz. Aile üyeleri bu kayıtlara erişemez.")
                                .font(.subheadline)
                        } icon: {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }

                Section("Hareketler") {
                    if expenses.isEmpty {
                        ContentUnavailableView(
                            "Bu ay kayıt yok", systemImage: "tray",
                            description: Text("Sağ üstteki + ile harcama ekleyin."))
                    }
                    ForEach(expenses) { ExpenseRow(expense: $0) }
                }
            }
            .listSectionSpacing(.compact)
            .onAppear {
                if Demo.value("scroll") == "payments" { proxy.scrollTo("payments", anchor: .top) }
            }
            }
            .navigationDestination(item: $demoPage) { page in
                switch page {
                case "installments": InstallmentsView()
                case "subscriptions": SubscriptionsView()
                case "statements": StatementsView()
                default: StatisticsView()
                }
            }
            .navigationTitle("Bütçe")
            .navigationSubtitle(Date.now.formatted(.dateTime.month(.wide).year()))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Ekim 2026") {}
                        Button("Eylül 2026") {}
                    } label: {
                        Label("Ay seç", systemImage: "calendar")
                    }
                }
                QuickAddToolbarItem(store: store)
            }
        }
    }

    private var changeText: String {
        let change = store.changeFromLastMonth
        let percent = abs(change).formatted(.percent.precision(.fractionLength(0)))
        let direction = change <= 0 ? "az" : "fazla"
        return "Geçen ayın aynı dönemine göre %\(percent.replacingOccurrences(of: "%", with: "")) \(direction) harcandı. Ortak gelir: \(store.monthlyIncome.lira)."
    }

    /// Budget, spent and what is left of the budget: three numbers that add up.
    @ViewBuilder
    private var summary: some View {
        let remaining = store.monthlyBudget - store.spentThisMonth
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                LabeledContent("Bütçe", value: store.monthlyBudget.lira)
                LabeledContent("Harcanan", value: store.spentThisMonth.lira)
                LabeledContent("Kalan", value: remaining.lira)
            }
            .monospacedDigit()
        } else {
            HStack(spacing: 0) {
                figure("Bütçe", store.monthlyBudget, tint: .primary)
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

private struct CategoryRow: View {
    let category: BudgetCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(category.name, systemImage: category.symbol)
                Spacer()
                Text("\(category.spent.lira) / \(category.limit.lira)")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(category.ratio > 1 ? Color("Warning") : .secondary)
            }
            ProgressView(value: min(category.ratio, 1))
                .tint(category.ratio > 0.85 ? Color("Warning") : .accentColor)
            if category.ratio > 1 {
                Text("Limit \((category.spent - category.limit).lira) aşıldı")
                    .font(.footnote)
                    .foregroundStyle(Color("Warning"))
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            MemberAvatar(member: expense.paidBy)
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                Text("\(expense.category) · \(expense.date, format: .relative(presentation: .named))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("−\(expense.amount.lira)")
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}
