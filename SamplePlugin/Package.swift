// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "EmceeTestPlugin",
    products: [
        .executable(name: "Plugin", targets: ["TestPlugin"]),
    ],
    dependencies: [
        .package(path: "../")
    ],
    targets: [
        .target(
            name: "TestPlugin",
            dependencies: [
                "EmceePlugin"
            ])
    ]
)
