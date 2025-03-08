//
// Macaroni
// Macaroni
//
// Created by Alex Babaev on 20 March 2021.
// Copyright © 2021 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/main/LICENSE
//

/// Logging levels that are used by Macaroni.
public enum MacaroniLoggingLevel: Equatable {
    case debug
    case error
}

/// Simple logging protocol. You can implement it to send Macaroni logs to your logging system.
public protocol MacaroniLogger {
    func log(_ message: String, level: MacaroniLoggingLevel, file: StaticString, function: String, line: UInt)
    func die(_ message: String, file: StaticString, function: String, line: UInt) -> Never
}

/// Default Macaroni logging methods.
extension MacaroniLogger {
    @inlinable
    func log(message: @autoclosure () -> String, level: MacaroniLoggingLevel, file: StaticString = #fileID, function: String = #function, line: UInt = #line) {
        log(message(), level: level, file: file, function: function, line: line)
    }

    @inlinable
    func debug(message: @autoclosure () -> String, file: StaticString = #fileID, function: String = #function, line: UInt = #line) {
        log(message(), level: .debug, file: file, function: function, line: line)
    }

    @inlinable
    func die(message: @autoclosure () -> String, file: StaticString = #fileID, function: String = #function, line: UInt = #line) -> Never {
        log(message(), level: .error, file: file, function: function, line: line)
        die(message(), file: file, function: function, line: line)
    }
}

/// Default Macaroni logger, that shows everything in the console.
public final class SimpleMacaroniLogger: MacaroniLogger {
    public init() {
    }

    public func log(_ message: String, level: MacaroniLoggingLevel, file: StaticString, function: String, line: UInt) {
        let levelString: String
        switch level {
            case .debug: levelString = "👣"
            case .error: levelString = "👿"
        }
        print("\(levelString) \(file):\(line) \(message)")
    }

    public func die(_ message: String, file: StaticString, function: String, line: UInt) -> Never {
        fatalError("Fatal error occurred during dependency resolving: \(message)", file: file, line: line)
    }
}

/// Macaroni logger that discards all logging messages.
public final class DisabledMacaroniLogger: MacaroniLogger {
    public init() {
    }

    public func log(_ message: String, level: MacaroniLoggingLevel, file: StaticString, function: String, line: UInt) {}

    public func die(_ message: String, file: StaticString, function: String, line: UInt) -> Never {
        fatalError("Fatal error occurred during dependency resolving: \(message)", file: file, line: line)
    }
}
