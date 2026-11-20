import Testing

@testable import Core

@Suite("Household name")
struct HouseholdNameTests {
    @Test func trimsSurroundingWhitespace() throws {
        let name = try HouseholdName("  Yılmaz Ailesi \n")
        #expect(name.value == "Yılmaz Ailesi")
    }

    @Test(arguments: ["", "   ", "\n\t"])
    func rejectsBlank(_ raw: String) {
        #expect(throws: ValidationError.empty) { try HouseholdName(raw) }
    }

    @Test func acceptsSixtyCharacters() throws {
        let name = try HouseholdName(String(repeating: "ş", count: 60))
        #expect(name.value.count == 60)
    }

    @Test func rejectsSixtyOneCharacters() {
        #expect(throws: ValidationError.tooLong(maximum: 60)) {
            try HouseholdName(String(repeating: "a", count: 61))
        }
    }

    @Test func countsUnicodeScalarsLikeThePostgresCheck() {
        // "🇹🇷" is one Character but two Unicode scalars; Postgres char_length counts scalars.
        #expect(throws: ValidationError.tooLong(maximum: 60)) {
            try HouseholdName(String(repeating: "🇹🇷", count: 31))
        }
    }
}

@Suite("Shopping item name")
struct ShoppingItemNameTests {
    @Test func trimsSurroundingWhitespace() throws {
        #expect(try ShoppingItemName("  Deterjan ").value == "Deterjan")
    }

    @Test func rejectsBlank() {
        #expect(throws: ValidationError.empty) { try ShoppingItemName("  ") }
    }

    @Test func acceptsOneHundredTwentyCharacters() throws {
        #expect(try ShoppingItemName(String(repeating: "x", count: 120)).value.count == 120)
    }

    @Test func rejectsOneHundredTwentyOneCharacters() {
        #expect(throws: ValidationError.tooLong(maximum: 120)) {
            try ShoppingItemName(String(repeating: "x", count: 121))
        }
    }
}

@Suite("Email address")
struct EmailAddressTests {
    @Test func normalisesCaseAndWhitespace() throws {
        #expect(try EmailAddress(" Ayse@Example.COM ").value == "ayse@example.com")
    }

    @Test func rejectsBlank() {
        #expect(throws: ValidationError.empty) { try EmailAddress(" ") }
    }

    @Test(arguments: ["ayse", "ayse@", "@example.com", "ayse@example", "ay se@example.com"])
    func rejectsMalformed(_ raw: String) {
        #expect(throws: ValidationError.invalidFormat) { try EmailAddress(raw) }
    }

    @Test func rejectsAddressesLongerThan254Characters() {
        let local = String(repeating: "a", count: 250)
        #expect(throws: ValidationError.tooLong(maximum: 254)) {
            try EmailAddress("\(local)@example.com")
        }
    }
}

@Suite("One-time code")
struct OneTimeCodeTests {
    @Test func acceptsSixDigits() throws {
        #expect(try OneTimeCode(" 123456 ").value == "123456")
    }

    @Test func rejectsBlank() {
        #expect(throws: ValidationError.empty) { try OneTimeCode("") }
    }

    @Test(arguments: ["12345", "1234567", "12a456", "١٢٣٤٥٦"])
    func rejectsAnythingButSixAsciiDigits(_ raw: String) {
        #expect(throws: ValidationError.invalidFormat) { try OneTimeCode(raw) }
    }
}

@Suite("Page request")
struct PageRequestTests {
    @Test func firstPageStartsAtZeroWithDefaultSize() {
        #expect(PageRequest.first == PageRequest(offset: 0, limit: 50))
    }

    @Test func limitIsClampedToTheMaximumPageSize() {
        #expect(PageRequest(offset: 0, limit: 500).limit == PageRequest.maximumLimit)
    }

    @Test func limitAndOffsetCannotBeNegativeOrZero() {
        let page = PageRequest(offset: -3, limit: 0)
        #expect(page.offset == 0)
        #expect(page.limit == 1)
    }

    @Test func nextPageAdvancesByLimit() {
        #expect(PageRequest.first.next == PageRequest(offset: 50, limit: 50))
    }
}
