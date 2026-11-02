// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "UnitClaimKit",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "UnitClaimKit", targets: ["UnitClaimKit"]),
        .executable(name: "UnitClaimDemo", targets: ["UnitClaimDemo"])
    ],
    targets: [
        .target(name: "UnitClaimKit"),
        .executableTarget(
            name: "UnitClaimDemo",
            dependencies: ["UnitClaimKit"]
        ),
        .testTarget(
            name: "UnitClaimKitTests",
            dependencies: ["UnitClaimKit"]
        )
    ],
    swiftLanguageModes: [.v6]
)
