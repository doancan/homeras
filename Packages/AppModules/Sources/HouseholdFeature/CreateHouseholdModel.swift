import Core
import Observation

/// State and actions of the "create your home" step shown to a user without a household.
@Observable
public final class CreateHouseholdModel {
    public enum Failure: Equatable {
        case invalidName(ValidationError)
        case repository(RepositoryError)
    }

    public var name = "" {
        didSet { if name != oldValue { error = nil } }
    }
    public private(set) var isSubmitting = false
    public private(set) var error: Failure?

    private let repository: any HouseholdRepository
    private let onCreated: (Household) -> Void

    /// - Parameter onCreated: Called once with the household the user now belongs to.
    public init(repository: any HouseholdRepository, onCreated: @escaping (Household) -> Void) {
        self.repository = repository
        self.onCreated = onCreated
    }

    public func create() async {
        guard !isSubmitting else { return }
        let householdName: HouseholdName
        do {
            householdName = try HouseholdName(name)
        } catch {
            self.error = .invalidName(error)
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }
        do {
            onCreated(try await repository.createHousehold(named: householdName))
        } catch .alreadyInHousehold {
            // Created from another device meanwhile: continue with that household.
            await continueWithExistingHousehold()
        } catch {
            self.error = .repository(error)
        }
    }

    private func continueWithExistingHousehold() async {
        do {
            if let existing = try await repository.currentHousehold() {
                onCreated(existing)
            } else {
                error = .repository(.unexpected)
            }
        } catch {
            self.error = .repository(error)
        }
    }
}
