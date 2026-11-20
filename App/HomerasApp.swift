import SwiftUI

@main
struct HomerasApp: App {
    @State private var launch = AppLaunch.fromMainBundle()

    var body: some Scene {
        WindowGroup {
            switch launch {
            case .ready(let root):
                RootView(root: root)
            case .misconfigured(let problem):
                MisconfiguredView(problem: problem)
            }
        }
    }
}

/// Composition root: validates configuration once and wires the live services.
enum AppLaunch {
    case ready(RootModel)
    case misconfigured(AppConfiguration.Invalid)

    static func fromMainBundle() -> AppLaunch {
        do {
            let configuration = try AppConfiguration(
                infoDictionary: Bundle.main.infoDictionary ?? [:])
            return .ready(RootModel(services: .live(configuration)))
        } catch {
            return .misconfigured(error)
        }
    }
}
