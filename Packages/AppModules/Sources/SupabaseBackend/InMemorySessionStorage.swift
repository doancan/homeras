import Foundation
import Supabase
import Synchronization

/// Session storage that lives and dies with the process.
final class InMemorySessionStorage: AuthLocalStorage {
    private let values = Mutex<[String: Data]>([:])

    func store(key: String, value: Data) throws {
        values.withLock { $0[key] = value }
    }

    func retrieve(key: String) throws -> Data? {
        values.withLock { $0[key] }
    }

    func remove(key: String) throws {
        _ = values.withLock { $0.removeValue(forKey: key) }
    }
}
