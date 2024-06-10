//
// Macaroni
// Macaroni
//
// Created by Alex Babaev on 20 August 2023.
// Copyright © 2023 Alex Babaev. All rights reserved.
//

import Foundation

public enum Macaroni {
    /// By default logging messages are being printed in the console.
    public nonisolated(unsafe) static var logger: MacaroniLogger = SimpleMacaroniLogger()

    public static func set(lookupPolicy: ContainerLookupPolicy) {
        Container.lookupPolicy = lookupPolicy
    }

    public static func set(logger: MacaroniLogger) {
        self.logger = logger
    }
}
