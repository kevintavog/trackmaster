// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "TrackMaster",
    products: [
        .executable(name: "Indexer", targets: ["Indexer"]),
        .executable(name: "Publish", targets: ["Publish"]),
        .executable(name: "TrackFilter", targets: ["TrackFilter"]),
        .executable(name: "TrackMaster", targets: ["TrackMaster"]),
        .executable(name: "Validator", targets: ["Validator"]),
        .library(name: "TrackMasterApp", targets: ["TrackMasterApp"]),
        .library(name: "TrackMasterCore", targets: ["TrackMasterCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nsomar/Guaka.git", from: "0.4.1"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        .package(url: "https://github.com/chenyunguiMilook/SwiftyXML.git", from: "3.0.2"),
        .package(url: "https://github.com/vapor/vapor.git", from: "3.3.3"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "1.4.0"),
        .package(url: "https://github.com/apple/swift-nio-zlib-support.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "TrackMaster",
            dependencies: ["Guaka", "TrackMasterApp"]),
        .target(
            name: "Indexer",
            dependencies: ["Guaka", "TrackMasterCore"]),
        .target(
            name: "Publish",
            dependencies: ["Guaka", "TrackMasterCore"]),
        .target(
            name: "Validator",
            dependencies: ["Guaka", "TrackMasterCore"]),
        .target(
            name: "TrackFilter",
            dependencies: ["Guaka", "TrackMasterCore"]),
        .target(
            name: "TrackMasterApp",
            dependencies: ["SwiftyJSON", "TrackMasterCore", "Vapor"]),
        .target(
            name: "TrackMasterCore",
            dependencies: ["SwiftyJSON", "SwiftyXML", "Vapor"]),
        .testTarget(
            name: "TrackMasterTests",
            dependencies: ["TrackMasterCore"]),
    ]
)
