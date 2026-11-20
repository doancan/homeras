import Foundation

/// Reads a Turkish bank's card-spending SMS on the device: amount, merchant, date, category guess,
/// refund, instalments and the card's last four digits. Nothing leaves the phone.
/// Prototype heuristics; the product needs per-bank formats and a test corpus (FR-073).
enum BankMessageParser {
    struct Result: Equatable {
        var amount: Decimal
        var merchant: String?
        var date: Date?
        var category: String?
        var isRefund = false
        var installmentCount: Int?
        var cardLast4: String?
    }

    static let sample =
        "YAPI KREDI: 20.11.2026 14:32 tarihinde MIGROS SANAL MARKET isyerinden 245,90 TL harcama yapilmistir. Kalan limit: 18.420,00 TL"

    private static let categoryKeywords: [(String, Set<String>)] = [
        ("Market", ["MIGROS", "A101", "BIM", "SOK", "CARREFOUR", "CARREFOURSA", "MACROCENTER", "FILE"]),
        ("Ulaşım", ["SHELL", "OPET", "BP", "PETROL", "TOTAL", "MARTI", "UBER"]),
        ("Faturalar", ["ENERJISA", "IGDAS", "TURKCELL", "VODAFONE", "TELEKOM", "SUPERONLINE"]),
        ("Sağlık", ["ECZANE", "HASTANE"]),
        ("Eğlence", ["SINEMA", "NETFLIX", "SPOTIFY", "BILET"]),
    ]

    static func parse(_ message: String) -> Result? {
        let upper = message.uppercased(with: Locale(identifier: "en_US_POSIX"))

        // One-time passwords are never expenses and must not be stored, even if they mention an amount.
        if upper.contains("SIFRE") || upper.contains("ŞIFRE") || upper.contains("DOGRULAMA")
            || upper.contains("DOĞRULAMA") || upper.contains("KODUNUZ")
        {
            return nil
        }

        guard let amount = spendingAmount(in: message) else { return nil }

        let merchant = message.firstMatch(of: /(?:tarihinde|ile)\s+(.+?)\s+(?:isyerinden|işyerinden)/)
            // Bank SMS text is ASCII upper case ("MIGROS"); Turkish casing would turn I into ı.
            .map { String($0.1).capitalized(with: Locale(identifier: "en_US_POSIX")) }

        var date: Date?
        if let match = message.firstMatch(of: /(\d{2})\.(\d{2})\.(\d{2,4})/),
            let day = Int(match.1), let month = Int(match.2), var year = Int(match.3)
        {
            if year < 100 { year += 2000 }
            date = Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
        }

        // Whole words of the merchant only: "SOKAK" must not match the SOK market.
        let words = Set((merchant ?? "").uppercased(with: Locale(identifier: "en_US_POSIX"))
            .split { !$0.isLetter && !$0.isNumber }.map(String.init))
        let category = categoryKeywords.first { _, keywords in !keywords.isDisjoint(with: words) }?.0

        let installments = message.firstMatch(of: /(\d{1,2})\s*taksit/).flatMap { Int($0.1) }
        let card = message.firstMatch(of: /\*{2,}[\s*]*(\d{4})/).map { String($0.1) }
        let isRefund = upper.contains("IADE") || upper.contains("İADE") || upper.contains("IPTAL")

        return Result(
            amount: amount, merchant: merchant, date: date, category: category, isRefund: isRefund,
            installmentCount: installments.flatMap { $0 > 1 ? $0 : nil }, cardLast4: card)
    }

    /// The first TL amount that is not a limit or balance ("Kullanılabilir limitiniz 18.420,00 TL").
    private static func spendingAmount(in message: String) -> Decimal? {
        for match in message.matches(of: /(\d{1,3}(?:\.\d{3})*,\d{2})\s*(?:TL|TRY)/) {
            let before = message[message.startIndex..<match.range.lowerBound].suffix(30)
                .uppercased(with: Locale(identifier: "en_US_POSIX"))
            if before.contains("LIMIT") || before.contains("BAKIYE") { continue }
            let digits = String(match.1).replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")
            if let value = Decimal(string: digits) { return value }
        }
        return nil
    }
}
