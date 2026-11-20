import SwiftUI

/// "What needs my attention today": budget, low stock, payments, reminders. One tap acts on each.
struct TodayView: View {
    @Environment(PrototypeStore.self) private var store
    @Binding var selection: AppTab
    @State private var isFamilyPresented = Demo.value("demo") == "family"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    BudgetSummaryRow()
                }

                if !store.lowStock.isEmpty {
                    Section {
                        ForEach(store.lowStock) { item in
                            LowStockRow(item: item)
                        }
                    } header: {
                        Text("Azalanlar")
                    } footer: {
                        Text("Minimum seviyeye inen ürünler. Listeye eklemek için dokunun.")
                    }
                }

                Section("Yaklaşan ödemeler") {
                    ForEach(store.payments) { payment in
                        HStack(spacing: 12) {
                            IconBadge(symbol: payment.symbol, tint: .accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(payment.title)
                                Text(payment.due, format: .relative(presentation: .named))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(payment.amount.lira)
                                .monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)
                    }
                }

                Section("Hatırlatıcılar") {
                    ForEach(store.reminders) { reminder in
                        HStack(spacing: 12) {
                            IconBadge(symbol: reminder.symbol, tint: Color("Mint"))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(reminder.title)
                                Text("\(reminder.detail) · \(reminder.due, format: .relative(presentation: .named))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .navigationTitle("Bugün")
            .navigationSubtitle(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isFamilyPresented = true
                    } label: {
                        FamilyAvatars(members: store.members)
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

private struct BudgetSummaryRow: View {
    @Environment(PrototypeStore.self) private var store

    private var ratio: Double {
        NSDecimalNumber(decimal: store.spentThisMonth / store.monthlyBudget).doubleValue
    }

    private var dailyAllowance: Decimal {
        max(0, store.monthlyBudget - store.spentThisMonth) / Decimal(store.remainingDays)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Kasım bütçesi")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(store.remainingDays) gün kaldı")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(store.spentThisMonth.lira)
                    .font(.largeTitle.weight(.semibold))
                    .monospacedDigit()
                Text("/ \(store.monthlyBudget.lira)")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            ProgressView(value: min(ratio, 1))
                .tint(ratio > 0.9 ? Color("Warning") : .accentColor)
            Text("Ay sonuna kadar günde \(dailyAllowance.formatted(.currency(code: "TRY").precision(.fractionLength(0)))) harcayabilirsiniz.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

private struct LowStockRow: View {
    @Environment(PrototypeStore.self) private var store
    let item: StockItem

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(symbol: item.symbol, tint: Color("Warning"))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                Text("\(item.quantity) \(item.unit) kaldı · \(item.place)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if store.isOnList(item) {
                Label("Listede", systemImage: "checkmark")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
            } else {
                Button {
                    withAnimation { store.addToList(item) }
                } label: {
                    Label("Listeye ekle", systemImage: "cart.badge.plus")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("\(item.name) listeye ekle")
            }
        }
        .sensoryFeedback(.success, trigger: store.isOnList(item))
    }
}
