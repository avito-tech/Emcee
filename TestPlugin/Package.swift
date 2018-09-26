// swift-tools-version:4.1

import PackageDescription

let package = Package(
    name: "EmceeTestPlugin",
    products: [
        .executable(name: "Plugin", targets: ["TestPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/avito-tech/Emcee", .branch("master"))
    ],
    targets: [
        .target(
            name: "TestPlugin",
            dependencies: [
                "EmceePlugin"
            ])
    ]
)
