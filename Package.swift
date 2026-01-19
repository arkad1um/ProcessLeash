// Copyright (C) 2026 ProcessLeash contributors
// Licensed under the GNU General Public License v3.0

// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProcessLeash",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ProcessLeash",
            targets: ["ProcessLeash"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ProcessLeash"
        ),
        .testTarget(
            name: "ProcessLeashTests",
            dependencies: ["ProcessLeash"]
        )
    ]
)
