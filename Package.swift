// swift-tools-version: 6.4

import Foundation
import PackageDescription

/// SwiftPM evaluates this manifest in its own process context. Prefer the
/// explicit Xcode selection, then the SDK selected by xcrun.
func contentsDirectory(fromDeveloperDirectory developerDirectory: URL) -> URL? {
    if developerDirectory.pathExtension == "app" {
        return developerDirectory.appending(path: "Contents")
    }

    let contentsDirectory = developerDirectory.deletingLastPathComponent()
    let xcodeDirectory = contentsDirectory.deletingLastPathComponent()

    guard developerDirectory.lastPathComponent == "Developer",
          contentsDirectory.lastPathComponent == "Contents",
          xcodeDirectory.pathExtension == "app"
    else {
        return nil
    }

    return contentsDirectory
}

func contentsDirectory(fromSDKRoot sdkRoot: URL) -> URL? {
    let sdkDirectory = sdkRoot.deletingLastPathComponent()
    let platformDeveloperDirectory = sdkDirectory.deletingLastPathComponent()
    let platformDirectory = platformDeveloperDirectory.deletingLastPathComponent()
    let platformsDirectory = platformDirectory.deletingLastPathComponent()
    let xcodeDeveloperDirectory = platformsDirectory.deletingLastPathComponent()
    let contentsDirectory = xcodeDeveloperDirectory.deletingLastPathComponent()
    let xcodeDirectory = contentsDirectory.deletingLastPathComponent()

    guard sdkRoot.pathExtension == "sdk",
          sdkDirectory.lastPathComponent == "SDKs",
          platformDeveloperDirectory.lastPathComponent == "Developer",
          platformDirectory.pathExtension == "platform",
          platformsDirectory.lastPathComponent == "Platforms",
          xcodeDeveloperDirectory.lastPathComponent == "Developer",
          contentsDirectory.lastPathComponent == "Contents",
          xcodeDirectory.pathExtension == "app"
    else {
        return nil
    }

    return contentsDirectory
}

func sharedFrameworksDirectoryPath(for environment: [String: String]) -> URL {
    if let developerDirectoryPath = environment["DEVELOPER_DIR"],
       !developerDirectoryPath.isEmpty,
       let contentsDirectory = contentsDirectory(
           fromDeveloperDirectory: URL(filePath: developerDirectoryPath)
       )
    {
        return contentsDirectory.appending(path: "SharedFrameworks")
    }

    if let sdkRootPath = environment["SDKROOT"],
       !sdkRootPath.isEmpty,
       let contentsDirectory = contentsDirectory(
           fromSDKRoot: URL(filePath: sdkRootPath)
       )
    {
        return contentsDirectory.appending(path: "SharedFrameworks")
    }

    return URL(filePath: "/Applications/Xcode.app/Contents/SharedFrameworks")
}

let sharedFrameworksDirectory = sharedFrameworksDirectoryPath(for: Context.environment)

/// Swift 6.4 enables the features marked enabled_in "6" automatically. Keep
/// only the still-upcoming features reported by the active Swift compiler:
/// /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -print-supported-features
let upcomingFeatures = [
    "ExistentialAny",
    "InternalImportsByDefault",
    "MemberImportVisibility",
    "InferIsolatedConformances",
    "NonisolatedNonsendingByDefault",
    "ImmutableWeakCaptures",
]

let swiftSettings = upcomingFeatures.map {
    SwiftSetting.enableUpcomingFeature($0)
} + [
    .strictMemorySafety(),
    .treatAllWarnings(as: .error),
]

let package = Package(
    name: "xcstrings-format",
    platforms: [
        .macOS(.v27),
    ],
    products: [
        .executable(
            name: "xcstrings-format",
            targets: ["XCStringsFormat"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            exact: "1.8.2"
        ),
    ],
    targets: [
        .target(
            name: "XCStringsParserBridge",
            path: "Sources/XCStringsParserBridge",
            publicHeadersPath: "include",
            cSettings: [
                .treatAllWarnings(as: .error),
            ]
        ),
        .executableTarget(
            name: "XCStringsFormat",
            dependencies: [
                "XCStringsParserBridge",
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
            ],
            swiftSettings: swiftSettings,
            linkerSettings: [
                .linkedFramework("XCStringsParser"),
                .unsafeFlags([
                    "-F\(sharedFrameworksDirectory.path)",
                    "-Xlinker", "-rpath",
                    "-Xlinker", sharedFrameworksDirectory.path,
                ]),
            ]
        ),
        .testTarget(
            name: "XCStringsFormatTests",
            dependencies: ["XCStringsFormat"],
            swiftSettings: swiftSettings
        ),
    ]
)
