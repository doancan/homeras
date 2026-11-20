import Charts
import SwiftUI

// Finance building blocks for the Bütçe tab: the payday number, payments (card statements,
// instalments, subscriptions), shared savings goals and statistics. Content layer only.

/// One number that answers "how much can we spend per day until payday?".
struct PaydayHero: View {
    @Environment(PrototypeStore.self) private var store

    private var remaining: Decimal { max(0, store.monthlyBudget - store.spentThisMonth) }
    private var daily: Decimal { remaining / Decimal(store.remainingDays) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Maaşa \(store.remainingDays) gün var")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 6) { dailyAmount; perDay }
                VStack(alignment: .leading, spacing: 0) { dailyAmount; perDay }
            }
            Text("Kalan \(remaining.lira) · maaş günü her ayın \(store.payday)'i")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .moneyPrivacy(store.hidesAmounts)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private var dailyAmount: some View {
        Text(daily.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
            .font(.largeTitle.weight(.bold))
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
            .moneyPrivacy(store.hidesAmounts)
    }

    private var perDay: some View {
        Text("günde harcayabilirsiniz")
            .font(.headline)
            .foregroundStyle(.secondary)
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
                            Text("Her ayın \(subscription.day)'i")
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
                    Text("Geçen aya göre")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(store.changeFromLastMonth, format: .percent.precision(.fractionLength(0)).sign(strategy: .always()))
                        .font(.largeTitle.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(store.changeFromLastMonth <= 0 ? Color.accentColor : Color("Warning"))
                    Text("Geçen ay \(store.lastMonthSpent.lira), bu ay şimdiye kadar \(store.spentThisMonth.lira)")
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
