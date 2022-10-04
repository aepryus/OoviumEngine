// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "OoviumEngine",
    platforms: [
		.iOS(.v13), .macOS(.v10_15)
    ],
    products: [
		.library(name: "OoviumEngine", targets: ["OoviumEngine", "Aegean"]),
		.executable(name: "oov", targets: ["Oov"]),
    ],
    dependencies: [
		.package(url: "https://github.com/aepryus/Acheron.git", branch: "master"),
    ],
    targets: [
		.target(name: "Aegean"),
		.target(name: "OoviumEngine", dependencies: ["Acheron", "Aegean"]),
        .executableTarget(name: "Oov", dependencies: ["OoviumEngine"]),
        .testTarget(name: "OoviumEngineTests", dependencies: ["OoviumEngine"]),
    ]
)
