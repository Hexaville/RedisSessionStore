// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "RedisSessionStore",
    targets: [
        Target(name: "RedisSessionStore"),
        Target(name: "RedisSessionStoreExample", dependencies: ["RedisSessionStore"])
    ],
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/Kitura-redis.git", majorVersion: 1),
        .Package(url: "https://github.com/noppoMan/HexavilleFramework.git", majorVersion: 0, minor: 1)
    ]
)
