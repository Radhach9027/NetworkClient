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
    targets: [
        .target(
            name: "NetworkClient",
            resources: [.process("Resources/HTTPErrors.json")]),
        .testTarget(
            name: "NetworkClientTests",
            dependencies: ["NetworkClient"]),
    ]
)
