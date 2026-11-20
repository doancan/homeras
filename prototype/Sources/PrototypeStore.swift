import Foundation
import Observation
import SwiftUI

// In-memory sample data for the UX prototype. Everything resets on relaunch.

struct Member: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let role: String
    let color: Color
    var initial: String { String(name.prefix(1)) }
}

struct ShoppingEntry: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var quantity: String
    var category: String
    var addedBy: Member
    var isInCart = false
    var linkedStockID: StockItem.ID?
}

struct StockItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var quantity: Int
    var unit: String
    var minimum: Int
    var place: String
    var symbol: String
    var isLow: Bool { quantity <= minimum }
}

struct Belonging: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var symbol: String
    var room: String
    var path: [String]
    var purchased: Date
    var price: Decimal
    var store: String
    var warrantyEnds: Date?
    var documents: [String]
    var maintenance: String?
}

struct Expense: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var category: String
    var amount: Decimal
    var date: Date
    var paidBy: Member
    var isPersonal: Bool
}

struct BudgetCategory: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var symbol: String
    var spent: Decimal
    var limit: Decimal
    var ratio: Double { NSDecimalNumber(decimal: spent / limit).doubleValue }
}

struct UpcomingPayment: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var amount: Decimal
    var due: Date
    var symbol: String
}

struct Reminder: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var detail: String
    var due: Date
    var symbol: String
}

@Observable
final class PrototypeStore {
    let householdName = "Yılmaz Ailesi"
    let members: [Member]
    var me: Member { members[0] }

    var shopping: [ShoppingEntry]
    var stock: [StockItem]
    var belongings: [Belonging]
    var expenses: [Expense]
    var categories: [BudgetCategory]
    var payments: [UpcomingPayment]
    var reminders: [Reminder]

    let monthlyBudget: Decimal = 25_000
    let monthlyIncome: Decimal = 52_000

    /// Blurs money amounts (Revolut's "hide balances"): useful on a phone the family shares.
    var hidesAmounts = false
    /// False until someone else has joined; the sample household starts with three members.
    var hasInvitedFamily = true
    /// Things this household buys again and again (Target's "My Usuals").
    var usuals = ["Ekmek", "Süt", "Yumurta", "Muz", "Kahve"]
    var recentSearches = ["Garanti", "AA pil", "Fatura"]
    /// A household that has just been created: no list, stock or spending yet.
    var isFresh: Bool { shopping.isEmpty && stock.isEmpty && expenses.isEmpty }
    var setupSteps: [(title: String, detail: String, isDone: Bool)] {
        [
            ("Aileni davet et", "Liste ve bütçe herkesle paylaşılır", hasInvitedFamily),
            ("İlk ürünü listeye ekle", "“Hızlı ekle” ile birkaç saniyede", !shopping.isEmpty),
            ("Aylık bütçeni belirle", "Harcadıkça ayın gidişatını görürsün", false),
        ]
    }

    func addToList(usual name: String) {
        guard !shopping.contains(where: { $0.name == name && !$0.isInCart }) else { return }
        shopping.append(ShoppingEntry(name: name, quantity: "", category: "Diğer", addedBy: me))
    }

    func remember(search query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        recentSearches.removeAll { $0.searchKey == trimmed.searchKey }
        recentSearches.insert(trimmed, at: 0)
        recentSearches = Array(recentSearches.prefix(5))
    }

    /// Empties the sample household to show the first-run experience.
    func resetToFreshHousehold() {
        hasInvitedFamily = false
        shopping = []
        stock = []
        belongings = []
        expenses = []
        payments = []
        reminders = []
        categories = categories.map { BudgetCategory(name: $0.name, symbol: $0.symbol, spent: 0, limit: $0.limit) }
    }

    init() {
        let elif = Member(name: "Elif", role: "Sahip", color: .indigo)
        let can = Member(name: "Can", role: "Üye", color: Color(red: 0.70, green: 0.33, blue: 0.10))
        let deniz = Member(name: "Deniz", role: "Üye", color: Color(red: 0.08, green: 0.45, blue: 0.47))
        members = [elif, can, deniz]

        let calendar = Calendar.current
        func days(_ value: Int) -> Date { calendar.date(byAdding: .day, value: value, to: .now) ?? .now }
        func months(_ value: Int) -> Date { calendar.date(byAdding: .month, value: value, to: .now) ?? .now }

        let detergent = StockItem(
            name: "Bulaşık deterjanı", quantity: 1, unit: "adet", minimum: 1, place: "Mutfak",
            symbol: "drop")
        let laundry = StockItem(
            name: "Çamaşır deterjanı", quantity: 2, unit: "kutu", minimum: 1, place: "Banyo",
            symbol: "washer")
        let batteries = StockItem(
            name: "AA pil", quantity: 2, unit: "adet", minimum: 4, place: "Çalışma odası",
            symbol: "battery.50percent")
        let milk = StockItem(
            name: "Süt", quantity: 0, unit: "litre", minimum: 2, place: "Mutfak", symbol: "waterbottle")
        stock = [
            detergent, laundry, batteries, milk,
            StockItem(name: "Kahve", quantity: 3, unit: "paket", minimum: 1, place: "Mutfak", symbol: "cup.and.saucer"),
            StockItem(name: "Tuvalet kâğıdı", quantity: 12, unit: "rulo", minimum: 6, place: "Banyo", symbol: "scroll"),
            StockItem(name: "Diş macunu", quantity: 1, unit: "adet", minimum: 1, place: "Banyo", symbol: "mouth"),
            StockItem(name: "Çöp torbası", quantity: 30, unit: "adet", minimum: 10, place: "Kiler", symbol: "trash"),
            StockItem(name: "Zeytinyağı", quantity: 1, unit: "şişe", minimum: 1, place: "Kiler", symbol: "flask"),
        ]

        shopping = [
            ShoppingEntry(name: "Süt", quantity: "2 litre", category: "Süt ve kahvaltı", addedBy: can, linkedStockID: milk.id),
            ShoppingEntry(name: "Yumurta", quantity: "15'li", category: "Süt ve kahvaltı", addedBy: elif),
            ShoppingEntry(name: "Beyaz peynir", quantity: "500 g", category: "Süt ve kahvaltı", addedBy: elif),
            ShoppingEntry(name: "Domates", quantity: "1 kg", category: "Manav", addedBy: can),
            ShoppingEntry(name: "Muz", quantity: "6 adet", category: "Manav", addedBy: deniz),
            ShoppingEntry(name: "Bulaşık deterjanı", quantity: "1 adet", category: "Temizlik", addedBy: elif, linkedStockID: detergent.id),
            ShoppingEntry(name: "Sünger", quantity: "3'lü", category: "Temizlik", addedBy: can),
        ]

        belongings = [
            Belonging(
                name: "HDMI kablo (2 m)", symbol: "cable.connector", room: "Salon",
                path: ["Salon", "TV ünitesi", "2. çekmece"], purchased: months(-14), price: 249,
                store: "Teknosa", warrantyEnds: nil, documents: [], maintenance: nil),
            Belonging(
                name: "Bulaşık makinesi", symbol: "dishwasher", room: "Mutfak",
                path: ["Mutfak"], purchased: months(-23), price: 18_999, store: "Arçelik",
                warrantyEnds: days(28), documents: ["Fatura.pdf", "Garanti belgesi.pdf"],
                maintenance: "Filtre temizliği her ay"),
            Belonging(
                name: "Klima", symbol: "air.conditioner.horizontal", room: "Salon",
                path: ["Salon"], purchased: months(-30), price: 27_500, store: "Daikin bayi",
                warrantyEnds: months(6), documents: ["Fatura.pdf"],
                maintenance: "Filtre değişimi 6 ayda bir"),
            Belonging(
                name: "Matkap seti", symbol: "wrench.and.screwdriver", room: "Depo",
                path: ["Depo", "Sol raf", "Mavi kutu"], purchased: months(-40), price: 3_450,
                store: "Koçtaş", warrantyEnds: nil, documents: [], maintenance: nil),
            Belonging(
                name: "Laptop şarj adaptörü", symbol: "powerplug", room: "Çalışma odası",
                path: ["Çalışma odası", "Masa", "Üst çekmece"], purchased: months(-8), price: 1_899,
                store: "Apple", warrantyEnds: months(4), documents: ["Fatura.pdf"], maintenance: nil),
            Belonging(
                name: "Yedek anahtarlar", symbol: "key", room: "Antre",
                path: ["Antre", "Vestiyer", "Küçük kutu"], purchased: months(-60), price: 0,
                store: "—", warrantyEnds: nil, documents: [], maintenance: nil),
        ]

        expenses = [
            Expense(title: "Migros", category: "Market", amount: 842.50, date: days(0), paidBy: elif, isPersonal: false),
            Expense(title: "Elektrik faturası", category: "Faturalar", amount: 1_240, date: days(-2), paidBy: elif, isPersonal: false),
            Expense(title: "Akaryakıt", category: "Ulaşım", amount: 2_150, date: days(-3), paidBy: can, isPersonal: false),
            Expense(title: "Sinema", category: "Eğlence", amount: 480, date: days(-4), paidBy: can, isPersonal: false),
            Expense(title: "Eczane", category: "Sağlık", amount: 365, date: days(-6), paidBy: elif, isPersonal: false),
            Expense(title: "Kitap", category: "Kişisel", amount: 320, date: days(-1), paidBy: elif, isPersonal: true),
            Expense(title: "Spor salonu", category: "Kişisel", amount: 1_100, date: days(-9), paidBy: elif, isPersonal: true),
        ]

        categories = [
            BudgetCategory(name: "Market", symbol: "cart", spent: 6_240, limit: 8_000),
            BudgetCategory(name: "Faturalar", symbol: "bolt", spent: 3_480, limit: 4_000),
            BudgetCategory(name: "Ulaşım", symbol: "car", spent: 3_900, limit: 5_000),
            BudgetCategory(name: "Eğlence", symbol: "popcorn", spent: 2_050, limit: 2_000),
            BudgetCategory(name: "Sağlık", symbol: "cross.case", spent: 1_210, limit: 2_500),
            BudgetCategory(name: "Ev", symbol: "sofa", spent: 1_540, limit: 3_500),
        ]

        payments = [
            UpcomingPayment(title: "Doğalgaz", amount: 1_870, due: days(3), symbol: "flame"),
            UpcomingPayment(title: "İnternet", amount: 449, due: days(5), symbol: "wifi"),
            UpcomingPayment(title: "Netflix", amount: 229.99, due: days(9), symbol: "play.tv"),
        ]

        reminders = [
            Reminder(title: "Klima filtresi", detail: "Değişim zamanı", due: days(2), symbol: "air.conditioner.horizontal"),
            Reminder(title: "Bulaşık makinesi garantisi", detail: "Garanti bitiyor", due: days(28), symbol: "checkmark.shield"),
        ]
    }

    // MARK: Derived

    var spentThisMonth: Decimal { categories.reduce(0) { $0 + $1.spent } }
    /// Out of stock first, then the lowest relative to its minimum.
    var lowStock: [StockItem] {
        stock.filter(\.isLow).sorted { lhs, rhs in
            if (lhs.quantity == 0) != (rhs.quantity == 0) { return lhs.quantity == 0 }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
    var monthName: String { Date.now.formatted(.dateTime.month(.wide)) }
    var upcomingTotal: Decimal { payments.reduce(0) { $0 + $1.amount } }
    var watchedCategories: [BudgetCategory] {
        categories.filter { $0.ratio >= 0.85 }.sorted { $0.ratio > $1.ratio }
    }
    var expiringWarranties: [Belonging] {
        belongings.filter { ($0.warrantyEnds?.timeIntervalSinceNow ?? .infinity) < 60 * 60 * 24 * 31 }
    }

    struct SpendPoint { let day: Date; let amount: Double }

    private static let dailySpend: [Double] = [
        620, 180, 1_240, 0, 950, 310, 2_150, 120, 0, 640, 480, 1_870, 365, 320, 2_190, 460, 1_380, 2_050, 2_253, 842,
    ]

    /// Cumulative spending from the 1st of the month to today (sample data).
    var cumulativeSpending: [SpendPoint] {
        guard !isFresh else { return [] }
        let calendar = Calendar.current
        let today = calendar.component(.day, from: .now)
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: .now)) ?? .now
        var total = 0.0
        return (0..<min(today, Self.dailySpend.count)).map { index in
            total += Self.dailySpend[index]
            let day = calendar.date(byAdding: .day, value: index, to: start) ?? start
            return SpendPoint(day: day, amount: total)
        }
    }

    /// An even pace from zero to the monthly budget on the last day.
    var budgetPace: [SpendPoint] {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: .now)) ?? .now
        let length = calendar.range(of: .day, in: .month, for: .now)?.count ?? 30
        let end = calendar.date(byAdding: .day, value: length - 1, to: start) ?? start
        let budget = NSDecimalNumber(decimal: monthlyBudget).doubleValue
        return [SpendPoint(day: start, amount: 0), SpendPoint(day: end, amount: budget)]
    }

    var plannedByToday: Decimal {
        let calendar = Calendar.current
        let length = calendar.range(of: .day, in: .month, for: .now)?.count ?? 30
        let today = calendar.component(.day, from: .now)
        return monthlyBudget * Decimal(today) / Decimal(length)
    }

    struct UpcomingEvent: Identifiable {
        let id = UUID()
        let date: Date
        let title: String
        let detail: String
        let amount: Decimal?
        let symbol: String
    }

    /// Payments, reminders and warranty ends on one timeline, soonest first.
    var upcoming: [UpcomingEvent] {
        let fromPayments = payments.map {
            UpcomingEvent(date: $0.due, title: $0.title, detail: "Ödeme", amount: $0.amount, symbol: $0.symbol)
        }
        let fromReminders = reminders.map {
            UpcomingEvent(date: $0.due, title: $0.title, detail: $0.detail, amount: nil, symbol: $0.symbol)
        }
        return (fromPayments + fromReminders).sorted { $0.date < $1.date }.prefix(5).map { $0 }
    }

    struct Activity: Identifiable {
        let id = UUID()
        let member: Member
        let text: String
        let date: Date
    }

    var activity: [Activity] {
        guard !isFresh else { return [] }
        return [
            Activity(member: members[1], text: "listeye Süt ve Domates ekledi", date: .now.addingTimeInterval(-60 * 25)),
            Activity(member: members[0], text: "Migros alışverişini kaydetti · ₺842,50", date: .now.addingTimeInterval(-60 * 60 * 3)),
            Activity(member: members[2], text: "Muz ekledi", date: .now.addingTimeInterval(-60 * 60 * 20)),
        ]
    }
    var cartCount: Int { shopping.filter(\.isInCart).count }
    var remainingDays: Int {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: .now) else { return 1 }
        return max(1, range.count - calendar.component(.day, from: .now) + 1)
    }

    func isOnList(_ item: StockItem) -> Bool {
        shopping.contains { $0.linkedStockID == item.id && !$0.isInCart }
    }

    // MARK: Actions

    func addToList(_ item: StockItem) {
        guard !isOnList(item) else { return }
        shopping.append(
            ShoppingEntry(
                name: item.name, quantity: "1 \(item.unit)", category: "Stoktan", addedBy: me,
                linkedStockID: item.id))
    }

    func addToList(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        shopping.append(ShoppingEntry(name: trimmed, quantity: "", category: "Diğer", addedBy: me))
    }

    func toggleCart(_ entry: ShoppingEntry) {
        guard let index = shopping.firstIndex(where: { $0.id == entry.id }) else { return }
        shopping[index].isInCart.toggle()
    }

    func remove(_ entry: ShoppingEntry) {
        shopping.removeAll { $0.id == entry.id }
    }

    func adjust(_ item: StockItem, by delta: Int) {
        guard let index = stock.firstIndex(where: { $0.id == item.id }) else { return }
        stock[index].quantity = max(0, stock[index].quantity + delta)
    }

    /// Moves bought items into stock and records one shared expense.
    func finishShopping(addToStock: Set<ShoppingEntry.ID>, total: Decimal) {
        for entry in shopping where entry.isInCart && addToStock.contains(entry.id) {
            if let stockID = entry.linkedStockID, let index = stock.firstIndex(where: { $0.id == stockID }) {
                stock[index].quantity += 1
            }
        }
        shopping.removeAll(where: \.isInCart)
        if total > 0 {
            expenses.insert(
                Expense(title: "Market alışverişi", category: "Market", amount: total, date: .now, paidBy: me, isPersonal: false),
                at: 0)
            if let index = categories.firstIndex(where: { $0.name == "Market" }) {
                categories[index].spent += total
            }
        }
    }

    func addExpense(title: String, amount: Decimal, category: String, isPersonal: Bool) {
        expenses.insert(
            Expense(title: title, category: category, amount: amount, date: .now, paidBy: me, isPersonal: isPersonal),
            at: 0)
        if !isPersonal, let index = categories.firstIndex(where: { $0.name == category }) {
            categories[index].spent += amount
        }
    }
}

extension String {
    /// Search key that ignores case, accents and the Turkish dotted/dotless i, so "hdmi" finds
    /// "HDMI" and "kilif" finds "KILIF" whatever the device locale.
    var searchKey: String {
        replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "İ", with: "i")
            .replacingOccurrences(of: "I", with: "i")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }

    func matchesSearch(_ query: String) -> Bool {
        query.isEmpty || searchKey.contains(query.searchKey)
    }
}

extension Double {
    /// Axis label in plain Turkish: "0", "500", "12,5 bin", "25 bin" (no ambiguous "B").
    var thousandsLabel: String {
        guard self >= 1_000 else { return formatted(.number.precision(.fractionLength(0))) }
        return "\((self / 1_000).formatted(.number.precision(.fractionLength(0...1)))) bin"
    }
}

extension Decimal {
    var lira: String { formatted(.currency(code: "TRY").precision(.fractionLength(0...2))) }
}
