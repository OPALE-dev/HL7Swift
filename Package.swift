// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HL7Swift",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "HL7Swift",
            targets: ["HL7Swift"]),
        .library(
            name: "FHIRSwift",
            targets: ["FHIRSwift"]),
        .library(
            name: "SwiftGenerator",
            targets: ["SwiftGenerator"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.37.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.17.2"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.0"),
        .package(url: "https://github.com/apple/FHIRModels.git", .upToNextMajor(from: "0.2.0")),
        .package(url: "https://github.com/swiftcsv/SwiftCSV.git", from: "0.6.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "HL7Swift",
            dependencies: [
                "SwiftGenerator",
                "SwiftCSV",
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOTLS", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ],
            resources: [
                .process("Resources"),
                .process("Spec/Resources"),
            ]),
        .target(
            name: "FHIRSwift",
            dependencies: [
                "HL7Swift",
                .product(name: "ModelsR4", package: "FHIRModels"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOTLS", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ],
            resources: [
                .process("Resources"),
            ]),
        .target(
            name: "SwiftGenerator"
        ),
        .target(
            name: "HL7CodeGen",
            dependencies: [
                "HL7Swift",
                "SwiftGenerator",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .target(
            name: "HL7Client",
            dependencies: [
                "HL7Swift",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .target(
            name: "HL7Server",
            dependencies: [
                "HL7Swift",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .testTarget(
            name: "HL7SwiftTests",
            dependencies: ["HL7Swift", "SwiftGenerator"],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "FHIRSwiftTests",
            dependencies: ["FHIRSwift", "HL7Swift"],
            resources: [
                .process("Resources"),
            ]
        )
    ]
)
