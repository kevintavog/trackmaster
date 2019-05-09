// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "TrackMaster",
    products: [
        .executable(name: "TrackMaster", targets: ["TrackMaster"]),
        .library(name: "TrackMasterCore", targets: ["TrackMasterCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nsomar/Guaka.git", from: "0.4.0"),
        // .package(url: "https://github.com/Alamofire/Alamofire.git", from: "4.8.2"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        // .package(url: "https://github.com/chenyunguiMilook/SwiftyXML.git", from: "2.0.0"), ??
        .package(url: "https://github.com/vapor/vapor.git", from: "3.3.0"),
    ],
    targets: [
        .target(
            name: "TrackMaster",
            dependencies: ["Guaka", "TrackMasterCore"]),
        .target(
            name: "TrackMasterCore",
            dependencies: ["SwiftyJSON", "Vapor"]),
        .testTarget(
            name: "TrackMasterTests",
            dependencies: ["TrackMaster"]),
    ]
)
