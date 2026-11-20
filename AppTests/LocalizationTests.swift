import Foundation
import TestSupport
import Testing

@testable import Homeras

@Suite("App localization")
struct LocalizationTests {
    @Test func catalogIsTranslatedIntoEveryAppLanguage() {
        let app = Bundle(for: AppBundleMarker.self)
        #expect(LocalizationAudit.keyCount(in: app, language: "tr") > 0)
        #expect(LocalizationAudit.missingKeys(in: app).isEmpty)
    }
}
