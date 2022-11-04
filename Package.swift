// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkClient",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "NetworkClient",
            targets: ["NetworkClient"]),
    ],
    dependencies: [
         .package(url: "https://github.com/ashleymills/Reachability.swift", branch: "master"),
    ],
    targets: [
        .target(
            name: "NetworkClient",
            dependencies: [.product(name: "Reachability", package: "Reachability.swift")],
            resources: [.process("Resources/HTTPErrors.json")]),
        .testTarget(
            name: "NetworkClientTests",
            dependencies: ["NetworkClient"]),
    ]
)
