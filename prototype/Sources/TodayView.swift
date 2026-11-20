import Charts
import SwiftUI

/// Today as a dashboard: the month's money, the household's open loops, what is coming up and
/// what the family just did. Every tile is a shortcut into the tab that owns it.
/// Content layer only: cards are solid grouped surfaces, never glass.
struct TodayView: View {
    @Environment(PrototypeStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    @Binding var selection: AppTab
    @State private var isFamilyPresented = Demo.value("demo") == "family"

    private var columns: [GridItem] {
        let count = typeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    private var stockDetail: String {
        let empty = store.lowStock.filter { $0.quantity == 0 }.count
        return empty > 0 ? "\(empty) ürün bitti" : "Minimumda olanlar"
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    BudgetCard()
                        .onTapGesture { selection = .budget }

                    LazyVGrid(columns: columns, spacing: 12) {
                        StatTile(
                            symbol: "cart", tint: .accentColor,
                            value: "\(store.shopping.filter { !$0.isInCart }.count) ürün",
                            title: "Alışveriş listesi",
                            detail: "\(Set(store.shopping.map(\.addedBy)).count) kişi ekledi"
                        ) { selection = .shopping }
                        StatTile(
                            symbol: "shippingbox", tint: Color("Warning"),
                            value: "\(store.lowStock.count) azalan",
                            title: "Stok",
                            detail: stockDetail
                        ) { selection = .home }
                        StatTile(
                            symbol: "calendar.badge.clock", tint: .accentColor,
                            value: store.upcomingTotal.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                            title: "Yaklaşan ödemeler",
                            detail: "\(store.payments.count) ödeme · ilki \(store.payments.first.map { $0.due.formatted(.relative(presentation: .named)) } ?? "—")"
                        ) { selection = .budget }
                        StatTile(
                            symbol: "chart.bar.xaxis", tint: Color("Warning"),
                            value: store.watchedCategories.first.map { "%\(Int(($0.ratio * 100).rounded()))" } ?? "Yolunda",
                            title: store.watchedCategories.first.map { "\($0.name) limiti" } ?? "Kategoriler",
                            detail: store.watchedCategories.count > 1
                                ? "+\(store.watchedCategories.count - 1) kategori %85 üzerinde"
                                : "Limitlere göre"
                        ) { selection = .budget }
                    }

                    LowStockCard()
                    UpcomingCard()
                    ActivityCard()
                        .id("activity")
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .onAppear {
                if Demo.value("demo") == "lower" { proxy.scrollTo("activity", anchor: .bottom) }
            }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Bugün")
            .navigationSubtitle(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isFamilyPresented = true
                    } label: {
                        // Title + icon so the item still reads when bars move to the side on iPhone Duo.
                        Label {
                            Text("Aile")
                        } icon: {
                            FamilyAvatars(members: store.members)
                        }
                        .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel("Aile ve ayarlar")
                }
            }
            .sheet(isPresented: $isFamilyPresented) {
                FamilySheet()
            }
        }
    }
}

// MARK: - Budget

private struct BudgetCard: View {
    @Environment(PrototypeStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var selectedDay: Date?

    private var dailyAllowance: Decimal {
        max(0, store.monthlyBudget - store.spentThisMonth) / Decimal(store.remainingDays)
    }

    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(store.monthName.capitalized(with: Locale(identifier: "tr_TR"))) bütçesi")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(store.remainingDays) gün kaldı")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                amounts

                SpendingPaceChart(selectedDay: $selectedDay)
                    .frame(height: typeSize.isAccessibilitySize ? 200 : 140)

                Label {
                    Text(paceSummary)
                } icon: {
                    Image(systemName: isUnderPlan ? "checkmark.circle" : "exclamationmark.circle")
                        .foregroundStyle(isUnderPlan ? Color.accentColor : Color("Warning"))
                }
                .font(.subheadline)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityHint("Bütçe sekmesini açar")
    }

    private var isUnderPlan: Bool { store.spentThisMonth <= store.plannedByToday }

    private var paceSummary: String {
        let difference = abs(NSDecimalNumber(decimal: store.plannedByToday - store.spentThisMonth).doubleValue)
        let amount = difference.formatted(.currency(code: "TRY").precision(.fractionLength(0)))
        let daily = dailyAllowance.formatted(.currency(code: "TRY").precision(.fractionLength(0)))
        return isUnderPlan
            ? "Planın \(amount) altındasınız. Ay sonuna kadar günde \(daily) harcayabilirsiniz."
            : "Planın \(amount) üzerindesiniz. Ay sonuna kadar günde \(daily) kalıyor."
    }

    private var amounts: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                spent
                limit
            }
            VStack(alignment: .leading, spacing: 2) {
                spent
                limit
            }
        }
    }

    private var spent: some View {
        Text(store.spentThisMonth.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
            .font(.largeTitle.weight(.semibold))
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
    }

    private var limit: some View {
        Text("/ \(store.monthlyBudget.formatted(.currency(code: "TRY").precision(.fractionLength(0))))")
            .font(.title3)
            .foregroundStyle(.secondary)
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
    }
}

/// Cumulative spending against an even pace to the monthly budget. One unit (₺), one axis.
private struct SpendingPaceChart: View {
    @Environment(PrototypeStore.self) private var store
    @Binding var selectedDay: Date?

    var body: some View {
        let points = store.cumulativeSpending
        let selected = selectedDay.flatMap { day in
            points.first { Calendar.current.isDate($0.day, inSameDayAs: day) }
        }

        Chart {
            ForEach(store.budgetPace, id: \.day) { point in
                LineMark(x: .value("Gün", point.day, unit: .day), y: .value("Tutar", point.amount), series: .value("Seri", "Plan"))
                    .foregroundStyle(Color.secondary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            }
            ForEach(points, id: \.day) { point in
                AreaMark(x: .value("Gün", point.day, unit: .day), y: .value("Tutar", point.amount))
                    .foregroundStyle(Color.accentColor.opacity(0.12))
                LineMark(x: .value("Gün", point.day, unit: .day), y: .value("Tutar", point.amount), series: .value("Seri", "Harcama"))
                    .foregroundStyle(Color.accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            if let selected {
                RuleMark(x: .value("Gün", selected.day, unit: .day))
                    .foregroundStyle(Color.secondary.opacity(0.4))
                    .annotation(position: .top, overflowResolution: .init(x: .fit, y: .disabled)) {
                        VStack(spacing: 2) {
                            Text(selected.day, format: .dateTime.day().month())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(selected.amount, format: .currency(code: "TRY").precision(.fractionLength(0)))
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemGroupedBackground), in: .rect(cornerRadius: 8))
                    }
                PointMark(x: .value("Gün", selected.day, unit: .day), y: .value("Tutar", selected.amount))
                    .foregroundStyle(Color.accentColor)
                    .symbolSize(60)
            }
        }
        .chartXSelection(value: $selectedDay)
        .chartLegend(.hidden)
        .chartYAxis {
            AxisMarks(position: .trailing, values: [0, 12_500, 25_000]) { value in
                AxisGridLine()
AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(amount.thousandsLabel)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 10)) {
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
            }
        }
        .chartOverlay { _ in
            // Legend as plain text so identity never depends on color alone.
            HStack(spacing: 12) {
                LegendKey(label: "Harcama", dashed: false)
                LegendKey(label: "Plan", dashed: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .allowsHitTesting(false)
        }
        // Axis text is capped so labels never collide; the values are read out in full below.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityLabel("Ay içi kümülatif harcama")
        .accessibilityValue("Bugüne kadar \(store.spentThisMonth.lira), plan \(store.plannedByToday.lira)")
    }
}

private struct LegendKey: View {
    let label: String
    let dashed: Bool

    var body: some View {
        HStack(spacing: 4) {
            Capsule()
                .stroke(
                    dashed ? Color.secondary : Color.accentColor,
                    style: StrokeStyle(lineWidth: 2, dash: dashed ? [3, 3] : []))
                .frame(width: 14, height: 2)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Tiles and cards

/// A surface for one dashboard block. Solid grouped background: cards are content, not glass.
struct DashboardCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 22))
    }
}

private struct StatTile: View {
    let symbol: String
    let tint: Color
    let value: String
    let title: String
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: symbol)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(tint)
                        .accessibilityHidden(true)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                Text(value)
                    .font(.title.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 22))
            .contentShape(.rect(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value). \(detail)")
    }
}

private struct CardHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct LowStockCard: View {
    @Environment(PrototypeStore.self) private var store

    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                CardHeader(title: "Azalanlar")
                ForEach(store.lowStock.prefix(3)) { item in
                    let onList = store.isOnList(item)
                    Button {
                        withAnimation { store.addToList(item) }
                    } label: {
                        HStack(spacing: 12) {
                            IconBadge(symbol: item.symbol, tint: Color("Warning"))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .foregroundStyle(.primary)
                                Text(item.quantity == 0 ? "Bitti · \(item.place)" : "\(item.quantity) \(item.unit) kaldı · \(item.place)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 8)
                            Label(onList ? "Listede" : "Listeye ekle", systemImage: onList ? "checkmark.circle.fill" : "cart.badge.plus")
                                .labelStyle(.iconOnly)
                                .font(.title3)
                                .foregroundStyle(onList ? Color.secondary : Color.accentColor)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .disabled(onList)
                    .accessibilityLabel(onList ? "\(item.name), listede" : "\(item.name) listeye ekle")
                    .sensoryFeedback(.success, trigger: onList)
                }
                if store.lowStock.count > 3 {
                    Text("+\(store.lowStock.count - 3) ürün daha")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct UpcomingCard: View {
    @Environment(PrototypeStore.self) private var store

    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                CardHeader(title: "Yaklaşanlar")
                ForEach(store.upcoming) { event in
                    HStack(spacing: 12) {
                        DateChip(date: event.date)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                            Text(event.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        if let amount = event.amount {
                            Text(amount.lira)
                                .monospacedDigit()
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

private struct DateChip: View {
    let date: Date

    var body: some View {
        VStack(spacing: 0) {
            Text(date, format: .dateTime.day())
                .font(.headline)
                .monospacedDigit()
            Text(date, format: .dateTime.month(.abbreviated))
                .font(.caption2.weight(.medium))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 40)
        .padding(.vertical, 6)
        .background(Color(.tertiarySystemGroupedBackground), in: .rect(cornerRadius: 10))
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }
}

private struct ActivityCard: View {
    @Environment(PrototypeStore.self) private var store

    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                CardHeader(title: "Ailede son hareketler")
                ForEach(store.activity) { activity in
                    HStack(alignment: .top, spacing: 12) {
                        MemberAvatar(member: activity.member)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Text(activity.member.name).fontWeight(.semibold)) \(activity.text)")
                            Text(activity.date, format: .relative(presentation: .named))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}
