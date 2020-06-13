// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Macaroni",
    platforms: [ .iOS(.v11), .macOS(.v10_14) ],
    products: [
        .library(name: "Macaroni", type: .static, targets: [ "Macaroni" ]),
        .executable(name: "Example", targets: [ "Example" ]),
    ],
    targets: [
        .target(name: "Macaroni", dependencies: [], path: "Sources"),
        .target(name: "Example", dependencies: [ "Macaroni" ], path: "Example")
    ],
    swiftLanguageVersions: [.v5]
)
