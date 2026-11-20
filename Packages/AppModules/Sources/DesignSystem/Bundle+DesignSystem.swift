import Foundation

extension Bundle {
    /// Shared strings (actions, errors) for use from feature modules, e.g.
    /// `Text("action.retry", bundle: .designSystem)`.
    nonisolated public static let designSystem = Bundle.module
}
