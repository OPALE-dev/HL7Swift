// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HL7Swift",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "HL7Swift",
            targets: ["HL7Swift"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "HL7Swift",
            dependencies: [.product(name: "NIO", package: "swift-nio")],
            resources: [
                .process("Resources"),
            ]),
        .target(
            name: "HL7Client",
            dependencies: [
                "HL7Swift",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .testTarget(
            name: "HL7SwiftTests",
            dependencies: ["HL7Swift"],
            resources: [
                .process("Resources"),
            ]
        )
    ]
)
