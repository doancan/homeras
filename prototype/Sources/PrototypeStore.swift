import Foundation
import Observation
import SwiftUI

// In-memory sample data for the UX prototype. Everything resets on relaunch.

struct Member: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let role: String
    let color: Color
    var isAdult = true
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

/// Who can see a record (ADR-0009): the whole household, only the adults, or only its owner.
enum Visibility: String, CaseIterable, Hashable {
    case household = "Ortak"
    case partners = "Eşimle"
    case personal = "Kişisel"

    var symbol: String {
        switch self {
        case .household: "house"
        case .partners: "person.2"
        case .personal: "lock"
        }
    }

    var explanation: String {
        switch self {
        case .household: "Evdeki herkes görür, ortak bütçeye yazılır."
        case .partners: "Yalnızca yetişkinler görür (ör. çocuklara sürpriz). Ortak bütçeye yazılır."
        case .personal: "Yalnızca siz görürsünüz; ortak toplamlara hiç girmez."
        }
    }
}

struct Expense: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var category: String
    var amount: Decimal
    var date: Date
    var paidBy: Member
    var visibility: Visibility = .household
    var isPersonal: Bool { visibility == .personal }
}

/// A member's salary or other regular income and the day it arrives.
struct IncomeSource: Identifiable, Hashable {
    let id = UUID()
    var member: Member
    var title: String
    var amount: Decimal
    var day: Int
}

/// "How much can we spend per day until the next income?", with every deduction visible.
struct SafeToSpend {
    struct Line: Identifiable {
        let id = UUID()
        let title: String
        let amount: Decimal
    }

    let cash: Decimal
    let deductions: [Line]
    let buffer: Decimal
    let nextIncome: IncomeSource?
    let nextIncomeDate: Date
    let days: Int

    var available: Decimal { max(0, cash - deductions.reduce(0) { $0 + $1.amount } - buffer) }
    var perDay: Decimal { available / Decimal(max(1, days)) }
}

enum SplitRule: String, CaseIterable, Hashable {
    case equal = "Eşit (%50/%50)"
    case byIncome = "Gelire orantılı"
}

enum BudgetMethod: String, CaseIterable, Hashable {
    case payday = "Maaş döngüsü"
    case monthly = "Takvim ayı"
    case envelope = "Zarf"
    case zeroBased = "Sıfır tabanlı"

    var explanation: String {
        switch self {
        case .payday: "Dönem maaş gününden maaş gününe sürer. Çoğu aile için önerilir."
        case .monthly: "Dönem ayın 1'inden sonuna sürer."
        case .envelope: "Her kategoriye baştan para ayrılır; zarf bitince o kategori durur."
        case .zeroBased: "Gelirin her lirası bir kategoriye ya da hedefe atanır."
        }
    }
}

struct BudgetCategory: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var symbol: String
    var color: Color = .accentColor
    var spent: Decimal
    var limit: Decimal
    var ratio: Double { limit > 0 ? NSDecimalNumber(decimal: spent / limit).doubleValue : 0 }
    /// One threshold everywhere: copy, colour and alerts all use 80% (FR-012).
    var isNearLimit: Bool { ratio >= PrototypeStore.limitWarningRatio }
}

/// A card purchase split into monthly instalments; only this month's share counts in the budget.
struct Installment: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var card: String
    var category: String
    var monthly: Decimal
    var paidCount: Int
    var totalCount: Int
    var remaining: Decimal { monthly * Decimal(totalCount - paidCount) }
}

struct Subscription: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var amount: Decimal
    var day: Int
    var symbol: String
}

struct CardStatement: Identifiable, Hashable {
    let id = UUID()
    var bank: String
    var amount: Decimal
    var due: Date
}

/// A shared savings goal; the monthly amount is derived from the target date.
struct SavingsGoal: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var symbol: String
    var saved: Decimal
    var target: Decimal
    var deadline: Date
    var ratio: Double { NSDecimalNumber(decimal: saved / target).doubleValue }
    var monthlyNeeded: Decimal {
        // Round partial months up so the monthly amount is never understated.
        let days = Calendar.current.dateComponents([.day], from: .now, to: deadline).day ?? 30
        let months = max(1, Int((Double(days) / 30.44).rounded(.up)))
        return max(0, target - saved) / Decimal(months)
    }
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
    var installments: [Installment] = []
    var subscriptions: [Subscription] = []
    var statements: [CardStatement] = []
    var goals: [SavingsGoal] = []
    static let limitWarningRatio = 0.8
    var incomes: [IncomeSource] = []
    /// Money in the members' current accounts today (sample; the product derives it from the ledger).
    var cashOnHand: Decimal = 24_000
    /// Kept aside so "safe to spend" never reaches zero exactly on payday.
    var safetyBuffer: Decimal = 1_000
    var budgetMethod = BudgetMethod.payday
    var splitRule = SplitRule.equal
    var quickAmounts: [Decimal] = [120, 250, 500, 1_000]
    /// Per-member notification choices (FR-071), keyed by member name in the prototype.
    var notifyOnPartnerExpense = true
    var notifyOnLimit = true
    var notifyOnPaymentDue = true
    var notifyOnChildExpense = false
    let lastMonthSpent: Decimal = 21_340
    /// Spending in the same days of last month (1st–20th), for an honest comparison.
    let lastMonthSamePeriodSpent: Decimal = 16_150
    /// Total spending of the last six months, oldest first (sample data).
    let monthlyHistory: [(month: String, amount: Double)] = [
        ("Haz", 19_850), ("Tem", 24_120), ("Ağu", 22_480), ("Eyl", 20_960), ("Eki", 21_340), ("Kas", 18_420),
    ]

    let monthlyBudget: Decimal = 25_000
    var monthlyIncome: Decimal { incomes.reduce(0) { $0 + $1.amount } }

    /// Blurs money amounts (Revolut's "hide balances"): useful on a phone the family shares.
    var hidesAmounts = false
    /// The quick-add sheet, opened from the trailing + of any tab.
    var isQuickAddPresented = false
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
            ("İlk ürünü listeye ekle", "Sağ üstteki + ile birkaç saniyede", !shopping.isEmpty),
            ("Aylık bütçeni belirle", "Harcadıkça ayın gidişatını görürsün", false),
        ]
    }

    /// Recently used merchants for one-tap entry, newest first, without duplicates.
    var recentMerchants: [(title: String, category: String, amount: Decimal)] {
        var seen = Set<String>()
        return expenses.compactMap { expense in
            guard !seen.contains(expense.title), expense.visibility != .personal else { return nil }
            seen.insert(expense.title)
            return (expense.title, expense.category, expense.amount)
        }
        .prefix(4).map { $0 }
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
        installments = []
        subscriptions = []
        statements = []
        goals = []
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
        let deniz = Member(name: "Deniz", role: "Çocuk", color: Color(red: 0.08, green: 0.45, blue: 0.47), isAdult: false)
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
            Expense(title: "Migros", category: "Market", amount: 842.50, date: days(0), paidBy: elif, visibility: .household),
            Expense(title: "Elektrik faturası", category: "Faturalar", amount: 1_240, date: days(-2), paidBy: elif, visibility: .household),
            Expense(title: "Akaryakıt", category: "Ulaşım", amount: 2_150, date: days(-3), paidBy: can, visibility: .household),
            Expense(title: "Sinema", category: "Eğlence", amount: 480, date: days(-4), paidBy: can, visibility: .household),
            Expense(title: "Eczane", category: "Sağlık", amount: 365, date: days(-6), paidBy: elif, visibility: .household),
            Expense(title: "Kitap", category: "Kişisel", amount: 320, date: days(-1), paidBy: elif, visibility: .personal),
            Expense(title: "Spor salonu", category: "Kişisel", amount: 1_100, date: days(-9), paidBy: elif, visibility: .personal),
            Expense(title: "Deniz'e doğum günü hediyesi", category: "Eğlence", amount: 900, date: days(-2), paidBy: can, visibility: .partners),
        ]

        categories = [
            BudgetCategory(name: "Market", symbol: "cart", color: Color(red: 0.16, green: 0.55, blue: 0.42), spent: 6_240, limit: 8_000),
            BudgetCategory(name: "Faturalar", symbol: "bolt", color: Color(red: 0.78, green: 0.45, blue: 0.12), spent: 3_480, limit: 4_000),
            BudgetCategory(name: "Ulaşım", symbol: "car", color: Color(red: 0.16, green: 0.44, blue: 0.74), spent: 3_900, limit: 5_000),
            BudgetCategory(name: "Eğlence", symbol: "popcorn", color: Color(red: 0.52, green: 0.33, blue: 0.75), spent: 2_050, limit: 2_000),
            BudgetCategory(name: "Sağlık", symbol: "cross.case", color: Color(red: 0.80, green: 0.25, blue: 0.30), spent: 1_210, limit: 2_500),
            BudgetCategory(name: "Ev", symbol: "sofa", color: Color(red: 0.50, green: 0.40, blue: 0.30), spent: 1_540, limit: 3_500),
        ]

        payments = [
            UpcomingPayment(title: "Doğalgaz", amount: 1_870, due: days(3), symbol: "flame"),
            UpcomingPayment(title: "İnternet", amount: 449, due: days(5), symbol: "wifi"),
            UpcomingPayment(title: "Netflix", amount: 229.99, due: days(9), symbol: "play.tv"),
        ]

        incomes = [
            IncomeSource(member: elif, title: "Maaş", amount: 30_000, day: 15),
            IncomeSource(member: can, title: "Maaş", amount: 22_000, day: 1),
        ]

        installments = [
            Installment(title: "Buzdolabı", card: "Yapı Kredi", category: "Ev", monthly: 2_000, paidCount: 1, totalCount: 6),
            Installment(title: "Telefon", card: "Garanti BBVA", category: "Elektronik", monthly: 1_250, paidCount: 4, totalCount: 12),
        ]
        subscriptions = [
            Subscription(name: "İnternet", amount: 449, day: 25, symbol: "wifi"),
            Subscription(name: "Netflix", amount: 229.99, day: 29, symbol: "play.tv"),
            Subscription(name: "Spotify Aile", amount: 149.99, day: 3, symbol: "music.note"),
            Subscription(name: "iCloud+", amount: 79.99, day: 12, symbol: "icloud"),
            Subscription(name: "Elektrik (ort.)", amount: 1_240, day: 18, symbol: "bolt"),
        ]
        statements = [
            CardStatement(bank: "Yapı Kredi", amount: 8_454, due: days(5)),
            CardStatement(bank: "Garanti BBVA", amount: 3_120, due: days(12)),
        ]
        goals = [
            SavingsGoal(name: "Aile tatili", symbol: "beach.umbrella", saved: 5_000, target: 20_000, deadline: months(12)),
            SavingsGoal(name: "Acil durum fonu", symbol: "lifepreserver", saved: 18_000, target: 30_000, deadline: months(8)),
        ]

        installments = [
            Installment(title: "Buzdolabı", card: "Yapı Kredi", category: "Ev", monthly: 2_000, paidCount: 1, totalCount: 6),
            Installment(title: "Telefon", card: "Garanti BBVA", category: "Elektronik", monthly: 1_250, paidCount: 4, totalCount: 12),
        ]
        subscriptions = [
            Subscription(name: "İnternet", amount: 449, day: 25, symbol: "wifi"),
            Subscription(name: "Netflix", amount: 229.99, day: 29, symbol: "play.tv"),
            Subscription(name: "Spotify Aile", amount: 149.99, day: 3, symbol: "music.note"),
            Subscription(name: "iCloud+", amount: 79.99, day: 12, symbol: "icloud"),
            Subscription(name: "Elektrik (ort.)", amount: 1_240, day: 18, symbol: "bolt"),
        ]
        statements = [
            CardStatement(bank: "Yapı Kredi", amount: 8_454, due: days(5)),
            CardStatement(bank: "Garanti BBVA", amount: 3_120, due: days(12)),
        ]
        goals = [
            SavingsGoal(name: "Aile tatili", symbol: "beach.umbrella", saved: 5_000, target: 20_000, deadline: months(12)),
            SavingsGoal(name: "Acil durum fonu", symbol: "lifepreserver", saved: 18_000, target: 30_000, deadline: months(8)),
        ]

        reminders = [
            Reminder(title: "Klima filtresi", detail: "Değişim zamanı", due: days(2), symbol: "air.conditioner.horizontal"),
            Reminder(title: "Bulaşık makinesi garantisi", detail: "Garanti bitiyor", due: days(28), symbol: "checkmark.shield"),
        ]
    }

    // MARK: Derived

    var spentThisMonth: Decimal { categories.reduce(0) { $0 + $1.spent } }
    var installmentsThisMonth: Decimal { installments.reduce(0) { $0 + $1.monthly } }
    var subscriptionsMonthly: Decimal { subscriptions.reduce(0) { $0 + $1.amount } }
    /// Change against last month as a ratio (−0.14 = 14% less).
    var changeFromLastMonth: Double? {
        guard lastMonthSpent > 0 else { return nil }
        return NSDecimalNumber(decimal: (spentThisMonth - lastMonthSpent) / lastMonthSpent).doubleValue
    }
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
        categories.filter(\.isNearLimit).sorted { $0.ratio > $1.ratio }
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
    /// The most recent income day on or before today: the current payday cycle starts here.
    var lastIncomeDate: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let previous = incomes.compactMap { income -> Date? in
            guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: today) else { return nil }
            let candidate = Self.nextOccurrence(of: income.day, after: calendar.date(byAdding: .day, value: -1, to: lastMonth) ?? lastMonth)
            let thisCycle = Self.nextOccurrence(of: income.day, after: candidate)
            return thisCycle <= today ? thisCycle : candidate
        }
        return previous.max() ?? today
    }

    /// Days until the next income of any adult; the payday cycle ends there.
    var remainingDays: Int { safeToSpend.days }

    /// The next date `day` falls on, clamped to short months and moved back to Friday when it is a
    /// weekend (Turkish banks pay on the previous working day).
    static func nextOccurrence(of day: Int, after date: Date = .now) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        for monthOffset in 0...2 {
            guard let month = calendar.date(byAdding: .month, value: monthOffset, to: today),
                let range = calendar.range(of: .day, in: .month, for: month)
            else { continue }
            var parts = calendar.dateComponents([.year, .month], from: month)
            parts.day = min(day, range.count)
            guard var candidate = calendar.date(from: parts) else { continue }
            let weekday = calendar.component(.weekday, from: candidate)
            if weekday == 7 { candidate = calendar.date(byAdding: .day, value: -1, to: candidate) ?? candidate }
            if weekday == 1 { candidate = calendar.date(byAdding: .day, value: -2, to: candidate) ?? candidate }
            if candidate > today { return candidate }
        }
        return calendar.date(byAdding: .month, value: 1, to: today) ?? today
    }

    var safeToSpend: SafeToSpend {
        let calendar = Calendar.current
        let next = incomes
            .map { ($0, Self.nextOccurrence(of: $0.day)) }
            .min { $0.1 < $1.1 }
        let nextDate = next?.1 ?? Self.nextOccurrence(of: 1)
        let days = max(1, calendar.dateComponents([.day], from: calendar.startOfDay(for: .now), to: nextDate).day ?? 1)

        var lines: [SafeToSpend.Line] = []
        for statement in statements where statement.due < nextDate {
            lines.append(.init(title: "\(statement.bank) ekstresi", amount: statement.amount))
        }
        let billsDue = subscriptions.filter { subscription in
            let due = Self.nextOccurrence(of: subscription.day)
            return due < nextDate
        }
        if !billsDue.isEmpty {
            lines.append(.init(title: "\(billsDue.count) fatura ve abonelik", amount: billsDue.reduce(0) { $0 + $1.amount }))
        }
        let goalShare = goals.reduce(Decimal(0)) { $0 + $1.monthlyNeeded }
        if goalShare > 0 {
            lines.append(.init(title: "Birikim hedefleri (bu ay)", amount: goalShare))
        }
        return SafeToSpend(
            cash: isFresh ? 0 : cashOnHand, deductions: isFresh ? [] : lines, buffer: isFresh ? 0 : safetyBuffer,
            nextIncome: next?.0, nextIncomeDate: nextDate, days: days)
    }

    /// Against the same days of last month, not the whole month (nil when there is no history).
    var changeFromSamePeriod: Double? {
        guard lastMonthSamePeriodSpent > 0 else { return nil }
        return NSDecimalNumber(decimal: (spentThisMonth - lastMonthSamePeriodSpent) / lastMonthSamePeriodSpent).doubleValue
    }

    var adults: [Member] { members.filter(\.isAdult) }

    /// Each adult's share of shared spending under the household's split rule.
    func share(of member: Member) -> Double {
        let adults = adults
        guard adults.contains(member) else { return 0 }
        switch splitRule {
        case .equal:
            return 1 / Double(adults.count)
        case .byIncome:
            let total = incomes.filter { $0.member.isAdult }.reduce(Decimal(0)) { $0 + $1.amount }
            let own = incomes.filter { $0.member == member }.reduce(Decimal(0)) { $0 + $1.amount }
            return total > 0 ? NSDecimalNumber(decimal: own / total).doubleValue : 1 / Double(adults.count)
        }
    }

    struct Balance: Identifiable {
        var id: Member.ID { member.id }
        let member: Member
        let paid: Decimal
        let owes: Decimal
        var net: Decimal { paid - owes }
    }

    /// Shared and partners-only spending this period: who paid what, who owes what.
    var balances: [Balance] {
        let shared = expenses.filter { $0.visibility != .personal }
        let total = shared.reduce(Decimal(0)) { $0 + $1.amount }
        return adults.map { member in
            let paid = shared.filter { $0.paidBy == member }.reduce(Decimal(0)) { $0 + $1.amount }
            let owes = total * Decimal(share(of: member))
            return Balance(member: member, paid: paid, owes: owes)
        }
    }

    /// "X, Y'ye ₺Z ödeyecek" for two adults; nil when even (within ₺1).
    var settlement: (from: Member, to: Member, amount: Decimal)? {
        let sorted = balances.sorted { $0.net < $1.net }
        guard let debtor = sorted.first, let creditor = sorted.last, debtor.member != creditor.member else { return nil }
        let amount = min(-debtor.net, creditor.net)
        guard amount >= 1 else { return nil }
        return (debtor.member, creditor.member, amount)
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
                Expense(title: "Market alışverişi", category: "Market", amount: total, date: .now, paidBy: me, visibility: .household),
                at: 0)
            if let index = categories.firstIndex(where: { $0.name == "Market" }) {
                categories[index].spent += total
            }
        }
    }

    func addExpense(
        title: String, amount: Decimal, category: String, visibility: Visibility = .household,
        paidBy: Member? = nil, date: Date = .now
    ) {
        expenses.insert(
            Expense(title: title, category: category, amount: amount, date: date, paidBy: paidBy ?? me, visibility: visibility),
            at: 0)
        if visibility != .personal, let index = categories.firstIndex(where: { $0.name == category }) {
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
    /// ₺1.240 for whole amounts, ₺245,90 otherwise: money never shows a single decimal digit.
    var lira: String {
        var rounded = Decimal()
        var copy = self
        NSDecimalRound(&rounded, &copy, 0, .plain)
        let digits = rounded == self ? 0 : 2
        return formatted(.currency(code: "TRY").precision(.fractionLength(digits)))
    }
}
