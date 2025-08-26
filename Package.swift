// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FaceTemplateRegistry",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FaceTemplateRegistry",
            targets: ["FaceTemplateRegistry"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AppliedRecognition/Ver-ID-Common-Types-Apple.git", .upToNextMajor(from: "3.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FaceTemplateRegistry",
            dependencies: [
                .product(name: "VerIDCommonTypes", package: "Ver-ID-Common-Types-Apple")
            ]),
        .testTarget(
            name: "FaceTemplateRegistryTests",
            dependencies: ["FaceTemplateRegistry"]),
    ]
)
