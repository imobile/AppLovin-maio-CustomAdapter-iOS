// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppLovinMaioMediationAdapter",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "AppLovinMaioMediationAdapter",
            targets: ["AppLovinMaioMediationAdapter"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/AppLovin/AppLovin-MAX-Swift-Package.git", from: "13.0.0"),
        .package(url: "https://github.com/imobile/MaioSDK-v2-iOS.git", from: "2.1.6")
    ],
    targets: [
        .target(
            name: "AppLovinMaioMediationAdapter",
            dependencies: [
                .product(name: "AppLovinSDK", package: "AppLovin-MAX-Swift-Package"),
                .product(name: "MaioSDK", package: "MaioSDK-v2-iOS")
            ],
            path: "AppLovinMaioMediationAdapter/AppLovinMaioMediationAdapter",
            publicHeadersPath: "."
        ),
        .testTarget(
            name: "AppLovinMaioMediationAdapterTests",
            dependencies: ["AppLovinMaioMediationAdapter"],
            path: "AppLovinMaioMediationAdapter/AppLovinMaioMediationAdapterTests"
        ),
    ]
)
