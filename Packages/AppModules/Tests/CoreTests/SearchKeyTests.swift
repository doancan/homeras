import Testing

@testable import Core

@Suite("Search key")
struct SearchKeyTests {
    @Test(arguments: [
        ("HDMI kablo", "hdmi"),
        ("KILIF", "kılıf"),
        ("İzmir", "izmir"),
        ("Süt", ""),
        ("Çiçek", "cicek"),
    ])
    func matchesIgnoringCaseAccentsAndDottedI(_ text: String, _ query: String) {
        #expect(text.matchesSearch(query))
    }

    @Test func doesNotMatchUnrelatedText() {
        #expect(!"Süt".matchesSearch("ekmek"))
    }
}
