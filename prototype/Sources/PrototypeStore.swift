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

    init() {
        let elif = Member(name: "Elif", role: "Sahip", color: .indigo)
        let can = Member(name: "Can", role: "Üye", color: .orange)
        let deniz = Member(name: "Deniz", role: "Üye", color: .teal)
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
    var lowStock: [StockItem] { stock.filter(\.isLow) }
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

extension Decimal {
    var lira: String { formatted(.currency(code: "TRY").precision(.fractionLength(0...2))) }
}
