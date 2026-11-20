// swift-tools-version: 6.2
import PackageDescription

let strict: [SwiftSetting] = [
    .treatAllWarnings(as: .error),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
]
let ui: [SwiftSetting] = strict + [.defaultIsolation(MainActor.self)]

let package = Package(
    name: "AppModules",
    defaultLocalization: "tr",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "SupabaseBackend", targets: ["SupabaseBackend"]),
        .library(name: "AuthFeature", targets: ["AuthFeature"]),
        .library(name: "HouseholdFeature", targets: ["HouseholdFeature"]),
        .library(name: "ShoppingFeature", targets: ["ShoppingFeature"]),
        // Linked only by test targets (package and app tests).
        .library(name: "TestSupport", targets: ["TestSupport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", exact: "2.55.7")
    ],
    targets: [
        .target(name: "Core", swiftSettings: strict),
        .target(
            name: "SupabaseBackend",
            dependencies: ["Core", .product(name: "Supabase", package: "supabase-swift")],
            swiftSettings: strict),
        .target(
            name: "DesignSystem", dependencies: ["Core"], resources: [.process("Resources")],
            swiftSettings: ui),
        .target(
            name: "AuthFeature", dependencies: ["Core", "DesignSystem"],
            resources: [.process("Resources")], swiftSettings: ui),
        .target(
            name: "HouseholdFeature", dependencies: ["Core", "DesignSystem"],
            resources: [.process("Resources")], swiftSettings: ui),
        .target(
            name: "ShoppingFeature", dependencies: ["Core", "DesignSystem"],
            resources: [.process("Resources")], swiftSettings: ui),
        // Shared test helpers; never linked into the app.
        .target(name: "TestSupport", path: "Tests/TestSupport", swiftSettings: strict),
        .testTarget(name: "CoreTests", dependencies: ["Core"], swiftSettings: strict),
        .testTarget(
            name: "DesignSystemTests", dependencies: ["DesignSystem", "TestSupport"],
            swiftSettings: strict),
        .testTarget(
            name: "SupabaseBackendTests", dependencies: ["SupabaseBackend"],
            swiftSettings: strict),
        .testTarget(
            name: "SupabaseBackendIntegrationTests", dependencies: ["SupabaseBackend"],
            swiftSettings: strict),
        .testTarget(
            name: "AuthFeatureTests", dependencies: ["AuthFeature", "TestSupport"],
            swiftSettings: strict),
        .testTarget(
            name: "HouseholdFeatureTests", dependencies: ["HouseholdFeature", "TestSupport"],
            swiftSettings: strict),
        .testTarget(
            name: "ShoppingFeatureTests", dependencies: ["ShoppingFeature", "TestSupport"],
            swiftSettings: strict),
    ],
    swiftLanguageModes: [.v6]
)
