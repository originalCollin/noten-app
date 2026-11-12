// swift-tools-version: 6.0
// AbiCore – die reine Rechenlogik des Abi-Rechners (ohne Oberfläche).
// Wird von der iPhone-App eingebunden und kann für sich allein getestet werden:
//   im Terminal:  swift test      (im Ordner ios/AbiCore)
//   in Xcode:     Schema "AbiCore" wählen und Cmd+U drücken

import PackageDescription

let package = Package(
    name: "AbiCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "AbiCore", targets: ["AbiCore"]),
    ],
    targets: [
        .target(name: "AbiCore"),
        .testTarget(name: "AbiCoreTests", dependencies: ["AbiCore"]),
    ]
)
