/// Offset pagination with a hard upper bound so no list query is unbounded.
public struct PageRequest: Hashable, Sendable {
    public static let maximumLimit = 50
    public static let first = PageRequest(offset: 0, limit: maximumLimit)

    public let offset: Int
    public let limit: Int

    public init(offset: Int, limit: Int) {
        self.offset = max(0, offset)
        self.limit = min(max(1, limit), Self.maximumLimit)
    }

    public var next: PageRequest {
        PageRequest(offset: offset + limit, limit: limit)
    }
}
