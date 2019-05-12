// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "TrackMaster",
    products: [
        .executable(name: "Indexer", targets: ["Indexer"]),
        .executable(name: "TrackMaster", targets: ["TrackMaster"]),
        .library(name: "TrackMasterApp", targets: ["TrackMasterApp"]),
        .library(name: "TrackMasterCore", targets: ["TrackMasterCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nsomar/Guaka.git", from: "0.4.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        // .package(url: "https://github.com/chenyunguiMilook/SwiftyXML.git", from: "2.0.0"), ?? Failing to resolve
        .package(url: "https://github.com/vapor/vapor.git", from: "3.3.0"),
    ],
    targets: [
        .target(
            name: "TrackMaster",
            dependencies: ["Guaka", "TrackMasterApp"]),
        .target(
            name: "Indexer",
            dependencies: ["Guaka", "TrackMasterCore"]),
        .target(
            name: "TrackMasterApp",
            dependencies: ["SwiftyJSON", "TrackMasterCore", "Vapor"]),
        .target(
            name: "TrackMasterCore",
            dependencies: ["SwiftyJSON", "Vapor"]),
        .testTarget(
            name: "TrackMasterTests",
            dependencies: ["TrackMasterCore"]),
    ]
)
