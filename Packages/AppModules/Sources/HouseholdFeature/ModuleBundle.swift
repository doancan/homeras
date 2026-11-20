import Foundation

/// This module's resource bundle (string catalog), reachable from tests via `@testable import`.
enum ModuleBundle {
    nonisolated static let bundle = Bundle.module
}
