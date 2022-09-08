// swift-tools-version:5.5

//
// Package.swift
// Macaroni
//
// Created by Alex Babaev on 20 March 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

import PackageDescription

let package = Package(
    name: "Macaroni",
    platforms: [ .iOS(.v11), .macOS(.v10_14) ],
    products: [
        .library(name: "Macaroni", targets: [ "Macaroni" ]),
    ],
    targets: [
        .target(name: "Macaroni", dependencies: [], path: "Sources"),

        .testTarget(name: "MacaroniTests", dependencies: ["Macaroni"]),
    ],
    swiftLanguageVersions: [.v5]
)
