// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "SecretSanta",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🐬 Fluent driver for MySQL.
        .package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.4.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.5.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // 🔐 JWT
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
        . package (url: "https://github.com/nodes-vapor/gatekeeper.git", from: "4.0.0"),

    ],
    targets: [
        .executableTarget(
            name: "SecretSanta",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentMySQLDriver", package: "fluent-mysql-driver"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "JWT", package: "jwt"),
                .product (name: "Gatekeeper", package: "gatekeeper"),
        
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "SecretSantaTests",
            dependencies: [
                .target(name: "SecretSanta"),
                .product(name: "VaporTesting", package: "vapor"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
