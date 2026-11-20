import Foundation

/// Checks that every string key of a module's catalog is translated into every app language.
public enum LocalizationAudit {
    public static let appLanguages = ["tr", "en"]

    /// Keys present in some language but missing in another, per language.
    /// Empty when the catalog is complete.
    public static func missingKeys(
        in bundle: Bundle, table: String = "Localizable", languages: [String] = appLanguages
    ) -> [String: Set<String>] {
        let keysByLanguage = Dictionary(
            uniqueKeysWithValues: languages.map { language in
                (language, keys(in: bundle, table: table, language: language))
            })
        let allKeys = keysByLanguage.values.reduce(into: Set<String>()) { $0.formUnion($1) }
        return keysByLanguage.reduce(into: [:]) { result, entry in
            let missing = allKeys.subtracting(entry.value)
            if !missing.isEmpty { result[entry.key] = missing }
        }
    }

    /// Number of keys in the catalog for a language; zero means the catalog was not bundled.
    public static func keyCount(in bundle: Bundle, table: String = "Localizable", language: String)
        -> Int
    {
        keys(in: bundle, table: table, language: language).count
    }

    private static func keys(in bundle: Bundle, table: String, language: String) -> Set<String> {
        var keys = Set<String>()
        for fileExtension in ["strings", "stringsdict"] {
            guard
                let url = bundle.url(
                    forResource: table, withExtension: fileExtension, subdirectory: nil,
                    localization: language),
                let entries = NSDictionary(contentsOf: url) as? [String: Any]
            else { continue }
            keys.formUnion(entries.keys)
        }
        return keys
    }
}
