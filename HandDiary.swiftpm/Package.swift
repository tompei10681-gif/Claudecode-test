// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "HandDiary",
    platforms: [
        .iOS("16.0")
    ],
    targets: [
        .executableTarget(
            name: "HandDiary",
            path: "Sources"
        )
    ]
)
