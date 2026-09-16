// swift-tools-version: 6.4

import Foundation
import PackageDescription

// SwiftPM evaluates this manifest in its own process context, so an alternate
// framework directory can be selected without changing the package source.
let sharedFrameworksDirectory = URL(
    filePath: Context.environment[
        "XCSTRINGS_FORMAT_SHARED_FRAMEWORKS"
    ] ?? "/Applications/Xcode.app/Contents/SharedFrameworks"
)

// Swift 6.4 enables the features marked enabled_in "6" automatically. Keep
// only the still-upcoming features reported by the active Swift compiler:
// /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -print-supported-features
let upcomingFeatures = [
    "ExistentialAny",
    "InternalImportsByDefault",
    "MemberImportVisibility",
    "InferIsolatedConformances",
    "NonisolatedNonsendingByDefault",
    "ImmutableWeakCaptures"
]

let swiftSettings = upcomingFeatures.map {
    SwiftSetting.enableUpcomingFeature($0)
} + [
    .strictMemorySafety(),
    .treatAllWarnings(as: .error)
]

let package = Package(
    name: "xcstrings-format",
    platforms: [
        .macOS(.v27)
    ],
    products: [
        .executable(
            name: "xcstrings-format",
            targets: ["XCStringsFormat"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            exact: "1.8.2"
        )
    ],
    targets: [
        .target(
            name: "XCStringsParserBridge",
            path: "Sources/XCStringsParserBridge",
            publicHeadersPath: "include",
            cSettings: [
                .treatAllWarnings(as: .error)
            ]
        ),
        .executableTarget(
            name: "XCStringsFormat",
            dependencies: [
                "XCStringsParserBridge",
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ],
            swiftSettings: swiftSettings,
            linkerSettings: [
                .linkedFramework("XCStringsParser"),
                .unsafeFlags([
                    "-F\(sharedFrameworksDirectory.path)",
                    "-Xlinker", "-rpath",
                    "-Xlinker", sharedFrameworksDirectory.path
                ])
            ]
        ),
        .testTarget(
            name: "XCStringsFormatTests",
            dependencies: ["XCStringsFormat"],
            swiftSettings: swiftSettings
        )
    ]
)
