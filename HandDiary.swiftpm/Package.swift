// swift-tools-version: 5.9
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
