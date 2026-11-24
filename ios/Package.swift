// swift-tools-version: 6.0

// Swift Package Manager manifest for React Native's SPM autolinking
// (react-native >= 0.87, `npx react-native spm`). CocoaPods users are
// unaffected and keep using react-native-uitextview.podspec.
//
// The autolinker references this package through a symlink at
// <app>/ios/build/generated/autolinking/libs/react-native-uitextview, and
// SwiftPM resolves the relative `.package(path:)` entries below against that
// symlink, so they point at the app's prebuilt React Native and codegen
// packages. The codegen output for RNUITextViewSpec is compiled by the app's
// React-GeneratedCode package and reaches us through ReactAppHeaders.

import PackageDescription

let package = Package(
    name: "react-native-uitextview",
    platforms: [.iOS("15.1")],
    products: [
        .library(name: "react-native-uitextview", targets: ["react-native-uitextview"]),
    ],
    dependencies: [
        .package(name: "ReactNative", path: "../../../../xcframeworks"),
        .package(name: "React-GeneratedCode", path: "../../../ios"),
    ],
    targets: [
        .target(
            name: "react-native-uitextview",
            dependencies: [
                .product(name: "ReactHeaders", package: "ReactNative"),
                .product(name: "ReactNativeHeaders", package: "ReactNative"),
                .product(name: "ReactNativeDependenciesHeaders", package: "ReactNative"),
                .product(name: "ReactAppHeaders", package: "React-GeneratedCode"),
            ],
            path: ".",
            // Listed explicitly so that this manifest and any local codegen
            // output under ios/generated are never picked up as sources.
            sources: [
                "RNUITextView.mm",
                "RNUITextViewChild.mm",
                "RNUITextViewManager.mm",
                "RNUITextViewShadowNode.cpp",
            ],
            publicHeadersPath: ".",
            cxxSettings: [
                // Must match the prebuilt React.framework's config-gated C++
                // ABI, otherwise the Release link fails on
                // DebugStringConvertible's vtable.
                .define("DEBUG", .when(configuration: .debug)),
                .define("NDEBUG", .when(configuration: .release)),
            ],
            linkerSettings: [
                .linkedFramework("UIKit"),
                .linkedFramework("Foundation"),
                .linkedFramework("CoreGraphics"),
            ]
        ),
    ],
    cxxLanguageStandard: .cxx20
)
