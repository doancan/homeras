import Core
import Foundation
import TestSupport
import Testing

@testable import HouseholdFeature

actor FakeHouseholdRepository: HouseholdRepository {
    var createResult: Result<Void, RepositoryError> = .success(())
    var existing: Household?
    private(set) var createdNames: [HouseholdName] = []
    private var gate: CheckedContinuation<Void, Never>?
    private var holds = false

    func setCreateResult(_ result: Result<Void, RepositoryError>) { createResult = result }
    func setExisting(_ household: Household?) { existing = household }
    func hold() { holds = true }
    func release() {
        holds = false
        gate?.resume()
        gate = nil
    }

    func currentHousehold() async throws(RepositoryError) -> Household? { existing }

    func createHousehold(named name: HouseholdName) async throws(RepositoryError) -> Household {
        createdNames.append(name)
        if holds { await withCheckedContinuation { gate = $0 } }
        try createResult.get()
        return Household(id: HouseholdID(UUID()), name: name)
    }
}

@MainActor
@Suite("Create household model", .timeLimit(.minutes(1)))
struct CreateHouseholdModelTests {
    let repository = FakeHouseholdRepository()

    func makeModel(onCreated: @escaping (Household) -> Void = { _ in }) -> CreateHouseholdModel {
        CreateHouseholdModel(repository: repository, onCreated: onCreated)
    }

    @Test func creatingReportsTheNewHousehold() async throws {
        var reported: Household?
        let model = makeModel { reported = $0 }
        model.name = "  Yılmaz Ailesi "

        await model.create()

        #expect(reported?.name.value == "Yılmaz Ailesi")
        #expect(model.error == nil)
    }

    @Test func aBlankNameIsRejectedLocally() async {
        let model = makeModel()
        model.name = " "

        await model.create()

        #expect(model.error == .invalidName(.empty))
        #expect(await repository.createdNames.isEmpty)
    }

    @Test func aTooLongNameIsRejectedLocally() async {
        let model = makeModel()
        model.name = String(repeating: "a", count: 61)

        await model.create()

        #expect(model.error == .invalidName(.tooLong(maximum: 60)))
    }

    @Test func aFailureKeepsTheNameAndReportsTheReason() async {
        await repository.setCreateResult(.failure(.offline))
        var reported: Household?
        let model = makeModel { reported = $0 }
        model.name = "Ev"

        await model.create()

        #expect(model.error == .repository(.offline))
        #expect(model.name == "Ev")
        #expect(reported == nil)
        #expect(!model.isSubmitting)
    }

    @Test func alreadyBelongingToAHouseholdContinuesWithThatHousehold() async throws {
        let existing = Household(id: HouseholdID(UUID()), name: try HouseholdName("Mevcut Ev"))
        await repository.setCreateResult(.failure(.alreadyInHousehold))
        await repository.setExisting(existing)
        var reported: Household?
        let model = makeModel { reported = $0 }
        model.name = "Yeni Ev"

        await model.create()

        #expect(reported == existing)
        #expect(model.error == nil)
    }

    @Test func aSecondSubmitWhileCreatingIsIgnored() async {
        await repository.hold()
        let model = makeModel()
        model.name = "Ev"

        let first = Task { await model.create() }
        while await repository.createdNames.isEmpty { await Task.yield() }
        #expect(model.isSubmitting)
        await model.create()
        await repository.release()
        await first.value

        #expect(await repository.createdNames.count == 1)
    }

    @Test func editingTheNameClearsTheError() async {
        let model = makeModel()
        model.name = ""
        await model.create()

        model.name = "E"

        #expect(model.error == nil)
    }

    @Test func catalogIsTranslatedIntoEveryAppLanguage() {
        #expect(LocalizationAudit.keyCount(in: ModuleBundle.bundle, language: "tr") > 0)
        #expect(LocalizationAudit.missingKeys(in: ModuleBundle.bundle).isEmpty)
    }
}
