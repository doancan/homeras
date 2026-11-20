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

    private var expenses: [Expense] {
        store.expenses.filter { $0.isPersonal == (scope == .personal) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Kapsam", selection: $scope) {
                        ForEach(Scope.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }

                switch scope {
                case .shared:
                    Section {
                        summary
                    } footer: {
                        Text("Bu ay ortak gelir: \(store.monthlyIncome.lira)")
                    }
                    Section("Son 14 gün") { spendingChart }
                    Section("Kategoriler") {
                        ForEach(store.categories) { CategoryRow(category: $0) }
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
                            description: Text("“Hızlı ekle” ile harcama ekleyin."))
                    }
                    ForEach(expenses) { ExpenseRow(expense: $0) }
                }
            }
            .listSectionSpacing(.compact)
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
            }
        }
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

    private var spendingChart: some View {
        let daily: [(Date, Double)] = (0..<14).map { offset in
            let day = Calendar.current.date(byAdding: .day, value: -13 + offset, to: .now) ?? .now
            let value = [420, 180, 0, 950, 310, 2150, 120, 0, 640, 480, 1240, 365, 320, 842][offset]
            return (day, Double(value))
        }
        return Chart(daily, id: \.0) { day, amount in
            BarMark(x: .value("Gün", day, unit: .day), y: .value("Tutar", amount))
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(3)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(amount.thousandsLabel)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: typeSize.isAccessibilitySize ? 7 : 4)) {
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
            }
        }
        .frame(height: 160)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .padding(.vertical, 6)
        .accessibilityLabel("Son 14 günün günlük harcama grafiği")
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
