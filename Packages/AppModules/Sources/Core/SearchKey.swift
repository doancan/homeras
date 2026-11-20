import Foundation

extension String {
    /// Search key that ignores case, accents and the Turkish dotted/dotless i, so "hdmi" finds
    /// "HDMI" and "kilif" finds "KILIF" whatever the device locale.
    public var searchKey: String {
        replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "İ", with: "i")
            .replacingOccurrences(of: "I", with: "i")
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: Locale(identifier: "en_US_POSIX"))
    }

    /// True when `query` is empty or its search key occurs in this string's search key.
    public func matchesSearch(_ query: String) -> Bool {
        query.isEmpty || searchKey.contains(query.searchKey)
    }
}
