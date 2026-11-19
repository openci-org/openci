// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "openci_virtual_ble",
    platforms: [.iOS(.v15)],
    products: [.library(name: "openci-virtual-ble", targets: ["openci_virtual_ble"])],
    dependencies: [.package(name: "FlutterFramework", path: "../FlutterFramework")],
    targets: [.target(
        name: "openci_virtual_ble",
        dependencies: [.product(name: "FlutterFramework", package: "FlutterFramework")]
    )]
)
