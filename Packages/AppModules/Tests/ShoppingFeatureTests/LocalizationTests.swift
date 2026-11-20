import TestSupport
import Testing

@testable import ShoppingFeature

@Suite("Shopping localization")
struct LocalizationTests {
    @Test func catalogIsTranslatedIntoEveryAppLanguage() {
        #expect(LocalizationAudit.keyCount(in: ModuleBundle.bundle, language: "tr") > 0)
        #expect(LocalizationAudit.missingKeys(in: ModuleBundle.bundle).isEmpty)
    }
}
