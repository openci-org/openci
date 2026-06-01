// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "app_minimizer_plus",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "app-minimizer-plus",
            targets: ["app_minimizer_plus"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "app_minimizer_plus",
            dependencies: [],
            path: "Sources/app_minimizer_plus",
            resources: []
        )
    ]
)
