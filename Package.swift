// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SuitEtecsaSdkSwift",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SuitEtecsaSdkSwift",
            targets: ["SuitEtecsaSdkSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.6.4")),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SuitEtecsaSdkSwift", dependencies: ["Alamofire", "SwiftSoup"]),
        .testTarget(
            name: "SuitEtecsaSdkSwiftTests",
            dependencies: ["SuitEtecsaSdkSwift"]),
    ]
)
