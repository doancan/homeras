import Core
import Foundation
import SwiftUI
import TestSupport
import Testing

@testable import DesignSystem

@MainActor
@Suite("Design system")
struct DesignSystemTests {
    @Test func catalogIsTranslatedIntoEveryAppLanguage() {
        #expect(LocalizationAudit.keyCount(in: Bundle.designSystem, language: "tr") > 0)
        #expect(LocalizationAudit.missingKeys(in: Bundle.designSystem).isEmpty)
    }

    @Test(arguments: [
        RepositoryError.offline, .notAuthenticated, .forbidden, .alreadyInHousehold, .rejected,
        .unexpected,
    ])
    func everyRepositoryErrorHasAMessage(_ error: RepositoryError) {
        let message = error.userMessage
        #expect(!message.isEmpty)
        #expect(!message.contains("error."), "a raw key means the translation is missing")
    }

    @Test(arguments: [AuthError.invalidOrExpiredCode, .rateLimited, .offline, .unexpected])
    func everyAuthErrorHasAMessage(_ error: AuthError) {
        let message = error.userMessage
        #expect(!message.isEmpty)
        #expect(!message.contains("error."))
    }

    @Test func tooLongMessageNamesTheLimit() {
        #expect(ValidationError.tooLong(maximum: 60).userMessage.contains("60"))
    }

    @Test func offlineAuthAndRepositoryMessagesMatch() {
        #expect(AuthError.offline.userMessage == RepositoryError.offline.userMessage)
    }

    @Test func undoActionIsTranslated() {
        let undo = String(localized: "action.undo", bundle: .designSystem)
        #expect(undo == "Geri al" || undo == "Undo")
    }

    @Test func semanticColoursResolveFromTheCatalog() {
        var light = EnvironmentValues()
        light.colorScheme = .light
        var dark = EnvironmentValues()
        dark.colorScheme = .dark
        // A colour missing from the catalog resolves to transparent black.
        for color in [Color.homerasWarning, Color.homerasMint] {
            #expect(color.resolve(in: light).opacity > 0)
            #expect(color.resolve(in: light).red != color.resolve(in: dark).red)
        }
    }
}
