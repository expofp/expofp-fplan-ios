// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ExpoFpFplan",
    platforms: [.iOS(.v14)],

    products: [
        .library(
            name: "ExpoFpFplan",
            targets: ["ExpoFpFplan"]),
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.17"),
        .package(url: "https://github.com/expofp/expofp-common-ios", from: "4.2.13"),
    ],
    targets: [
        .binaryTarget(name: "ExpoFpFplan",
                              path: "ExpoFpFplan.xcframework"
                ),
    ],
    swiftLanguageVersions: [.v5]
)
