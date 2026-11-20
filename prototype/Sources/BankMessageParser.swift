import Foundation

/// Reads a Turkish bank's card-spending SMS on the device: amount, merchant, date and a category
/// guess. Nothing leaves the phone. Prototype heuristics; the product needs per-bank formats.
enum BankMessageParser {
    struct Result: Equatable {
        var amount: Decimal
        var merchant: String?
        var date: Date?
        var category: String?
    }

    static let sample =
        "YAPI KREDI: 20.11.2026 14:32 tarihinde MIGROS SANAL MARKET isyerinden 245,90 TL harcama yapilmistir. Kalan limit: 18.420,00 TL"

    private static let categoryKeywords: [(String, [String])] = [
        ("Market", ["MIGROS", "A101", "BIM", "SOK", "CARREFOUR", "MACROCENTER", "FILE"]),
        ("Ulaşım", ["SHELL", "OPET", "BP", "PETROL", "TOTAL", "MARTI", "UBER"]),
        ("Faturalar", ["ENERJISA", "IGDAS", "TURKCELL", "VODAFONE", "TURK TELEKOM", "SUPERONLINE"]),
        ("Sağlık", ["ECZANE", "HASTANE"]),
        ("Eğlence", ["SINEMA", "NETFLIX", "SPOTIFY", "BILET"]),
    ]

    static func parse(_ message: String) -> Result? {
        // "1.245,90 TL" or "245,90 TL": the first amount is the spending; later ones are limits.
        guard let amountMatch = message.firstMatch(of: /(\d{1,3}(?:\.\d{3})*,\d{2})\s*(?:TL|TRY)/),
            let amount = Decimal(
                string: String(amountMatch.1).replacingOccurrences(of: ".", with: "")
                    .replacingOccurrences(of: ",", with: "."))
        else { return nil }

        let merchant = message.firstMatch(of: /(?:tarihinde|ile)\s+(.+?)\s+(?:isyerinden|işyerinden)/)
            // Bank SMS text is ASCII upper case ("MIGROS"); Turkish casing would turn I into ı.
            .map { String($0.1).capitalized(with: Locale(identifier: "en_US_POSIX")) }

        var date: Date?
        if let match = message.firstMatch(of: /(\d{2})\.(\d{2})\.(\d{4})/),
            let day = Int(match.1), let month = Int(match.2), let year = Int(match.3)
        {
            date = Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
        }

        let upper = message.uppercased(with: Locale(identifier: "tr_TR"))
        let category = categoryKeywords.first { _, keywords in
            keywords.contains { upper.contains($0) }
        }?.0

        return Result(amount: amount, merchant: merchant, date: date, category: category)
    }
}
