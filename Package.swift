// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HL7Swift",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
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
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.104.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.37.5"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.36.2"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.2"),
        .package(url: "https://github.com/apple/FHIRModels.git", .upToNextMajor(from: "0.9.3")),
        .package(url: "https://github.com/swiftcsv/SwiftCSV.git", from: "0.10.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.4.0")
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
                .copy("Spec/Resources/v2.3"),
                .copy("Spec/Resources/v2.3.1"),
                .copy("Spec/Resources/v2.4"),
                .copy("Spec/Resources/v2.5"),
                .copy("Spec/Resources/v2.5.1"),
                .copy("Spec/Resources/v2.6"),
                .copy("Spec/Resources/v2.7"),
                .copy("Spec/Resources/v2.7.1"),
                .copy("Spec/Resources/v2.8"),
                .copy("Spec/Resources/v2.8.1"),
                .copy("Spec/Resources/v2.8.2"),
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
        .executableTarget(
            name: "HL7CodeGen",
            dependencies: [
                "HL7Swift",
                "SwiftGenerator",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .executableTarget(
            name: "HL7Client",
            dependencies: [
                "HL7Swift",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .executableTarget(
            name: "HL7Server",
            dependencies: [
                "HL7Swift",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .executableTarget(
            name: "HL7Router",
            dependencies: [
                "HL7Swift",
                "Yams",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            resources: [
                .process("Resources")
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
    ],
    swiftLanguageModes: [.v5]
)
