// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FMSYSApp",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "FMSYSApp", targets: ["FMSYSApp"]),
        .library(name: "FMSYSCore", targets: ["FMSYSCore"]),
    ],
    targets: [
        .executableTarget(
            name: "FMSYSApp",
            dependencies: ["FMSYSCore"],
            path: "Sources/FMSYSApp"
        ),
        .target(
            name: "FMSYSCore",
            path: "Sources/FMSYSCore",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "FMSYSAppTests",
            dependencies: ["FMSYSCore"],
            path: "Tests/FMSYSAppTests"
        ),
    ]
)
