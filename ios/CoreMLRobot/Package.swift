// swift-tools-version: 5.9
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
            path: "CoreMLRobot"
        )
    ]
)
