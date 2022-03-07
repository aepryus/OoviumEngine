// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "OoviumEngine",
    platforms: [
		.iOS(.v11), .macOS(.v10_13)
    ],
    products: [
		.library(name: "OoviumEngine", targets: ["OoviumEngine"]),
		.executable(name: "oov", targets: ["Oov"]),
    ],
    dependencies: [
		.package(url: "https://github.com/aepryus/Acheron.git", from: "1.0.0"),
    ],
    targets: [
		.target(name: "Aegean"),
		.target(name: "OoviumEngine", dependencies: ["Acheron", "Aegean"]),
        .executableTarget(name: "Oov", dependencies: ["OoviumEngine"]),
        .testTarget(name: "OoviumEngineTests", dependencies: ["OoviumEngine"]),
    ]
)
