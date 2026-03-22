// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CoreMLRobot",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "CoreMLRobot", targets: ["CoreMLRobot"])
    ],
    targets: [
        .target(
            name: "CoreMLRobot",
            path: "CoreMLRobot",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
