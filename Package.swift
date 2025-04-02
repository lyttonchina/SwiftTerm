// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "SwiftTerm",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .visionOS(.v1)
    ],
    products: [
        .executable(name: "SwiftTermFuzz", targets: ["SwiftTermFuzz"]),
        .executable(name: "ThemeSwitchExample", targets: ["ThemeSwitchExample"]),
        //.executable(name: "CaptureOutput", targets: ["CaptureOutput"]),
        .library(
            name: "SwiftTerm",
            targets: ["SwiftTerm"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftTerm",
            dependencies: [],
            path: "Sources/SwiftTerm"
        ),
        .executableTarget (
            name: "SwiftTermFuzz",
            dependencies: ["SwiftTerm"],
            path: "Sources/SwiftTermFuzz"
        ),
        .executableTarget (
            name: "ThemeSwitchExample",
            dependencies: ["SwiftTerm"],
            path: "Examples/ThemeSwitchExample"
        ),
//        .target (
//            name: "CaptureOutput",
//            dependencies: ["SwiftTerm"],
//            path: "Sources/CaptureOutput"
//        ),        
        .testTarget(
            name: "SwiftTermTests",
            dependencies: ["SwiftTerm"],
            path: "Tests/SwiftTermTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
