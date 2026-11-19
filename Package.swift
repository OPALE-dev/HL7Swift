// swift-tools-version:6.2
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
            name: "HL7Core",
            targets: ["HL7Core"]),
        .library(
            name: "HL7Swift",
            targets: ["HL7Swift"]),
        .library(
            name: "HL7V2",
            targets: ["HL7V2"]),
        .library(
            name: "FHIR",
            targets: ["FHIR"]),
        .library(
            name: "CDA",
            targets: ["CDA"]),
        .library(
            name: "HL7Mapping",
            targets: ["HL7Mapping"]),
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
        // Keep FHIRModels 0.8.0, whose models the R4, R4B, and R5 adapters
        // are qualified against; 0.9 is a separate upgrade.
        .package(url: "https://github.com/apple/FHIRModels.git", exact: "0.8.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.4.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.5.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "HL7Core"),
        .target(
            name: "HL7Swift",
            dependencies: [
                "SwiftGenerator",
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOTLS", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]),
        .target(
            name: "HL7V2",
            dependencies: ["HL7Swift", "HL7Core", .product(name: "NIO", package: "swift-nio"), .product(name: "NIOSSL", package: "swift-nio-ssl")]),
        .target(
            name: "FHIR",
            dependencies: [
                "HL7Core",
                .product(name: "ModelsR4", package: "FHIRModels"),
                .product(name: "ModelsR4B", package: "FHIRModels"),
                .product(name: "ModelsR5", package: "FHIRModels"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ],
            path: "Sources/FHIRSwift"),
        .target(
            name: "CDA",
            dependencies: ["HL7Core"]),
        .target(
            name: "HL7Mapping",
            dependencies: [
                "HL7Core",
                "HL7V2",
                "FHIR",
                .product(name: "ModelsR4", package: "FHIRModels")
            ]),
        .target(
            name: "FHIRSwift",
            dependencies: ["FHIR", "HL7Mapping"],
            path: "Sources/FHIRSwiftCompatibility"),
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
            dependencies: ["HL7Swift", "SwiftGenerator", .product(name: "NIOEmbedded", package: "swift-nio")],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "FHIRSwiftTests",
            dependencies: [
                "FHIRSwift",
                "HL7Swift",
                .product(name: "ModelsR4", package: "FHIRModels"),
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "ArchitectureTests",
            dependencies: ["HL7V2", "FHIR", "CDA", "HL7Mapping"]
        ),
        .testTarget(
            name: "HL7CoreTests",
            dependencies: ["HL7Core"]
        ),
        .testTarget(
            name: "HL7V2PublicAPITests",
            dependencies: ["HL7V2"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "FHIRPublicAPITests",
            dependencies: ["FHIR"]
        ),
        .testTarget(
            name: "CDAPublicAPITests",
            dependencies: ["CDA"]
        ),
        .testTarget(
            name: "HL7MappingPublicAPITests",
            dependencies: ["HL7Mapping"]
        )
    ],
    swiftLanguageModes: [.v5]
)
