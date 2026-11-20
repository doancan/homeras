import SwiftUI

extension View {
    /// Segmented picker on iOS 26, the tabs style where the system provides it.
    @ViewBuilder
    public func contentSwitcherStyle() -> some View {
        // macOS 27.0 is listed because the package also builds for macOS.
        if #available(iOS 27.0, macOS 27.0, *) {
            pickerStyle(.tabs)
        } else {
            pickerStyle(.segmented)
        }
    }
}
