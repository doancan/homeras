public struct Household: Hashable, Sendable, Identifiable {
    public let id: HouseholdID
    public let name: HouseholdName

    public init(id: HouseholdID, name: HouseholdName) {
        self.id = id
        self.name = name
    }
}
