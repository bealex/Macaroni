//
// Macaroni
// Macaroni
//
// Created by Alex Babaev on 20 March 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

public enum MacaroniLoggingLevel: Equatable {
    case debug
    case error
}

public protocol MacaroniLogger {
    func log(_ message: String, level: MacaroniLoggingLevel, file: String, function: String, line: UInt)
    func die() -> Never
}

extension MacaroniLogger {
    func debug(_ message: String, file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    func deathTrap(_ message: String, file: String = #fileID, function: String = #function, line: UInt = #line) -> Never {
        log(message, level: .error, file: file, function: function, line: line)
        die()
    }
}

public final class SimpleMacaroniLogger: MacaroniLogger {
    public init() {
    }

    public func log(_ message: String, level: MacaroniLoggingLevel, file: String, function: String, line: UInt) {
        let levelString: String
        switch level {
            case .debug: levelString = "👣"
            case .error: levelString = "👿"
        }
        print("\(levelString) \(file):\(line) \(message)")
    }

    public func die() -> Never {
        fatalError("Fatal error occurred during dependency resolving.")
    }
}

public final class DisabledMacaroniLogger: MacaroniLogger {
    public init() {
    }

    public func log(_ message: String, level: MacaroniLoggingLevel, file: String, function: String, line: UInt) {}

    public func die() -> Never {
        fatalError("Fatal error occurred during dependency resolving.")
    }
}

public enum Macaroni {
    public static var logger: MacaroniLogger = SimpleMacaroniLogger()
}
