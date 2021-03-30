//
// Macaroni
// Macaroni
//
// Created by Alex Babaev on 20 March 2021.
// Copyright © 2020 Alex Babaev. All rights reserved.
// License: MIT License, https://github.com/bealex/Macaroni/blob/master/LICENSE
//

public enum MacaroniLoggingLevel: Equatable {
    case debug
    case error
}

public protocol MacaroniLogger {
    func log(_ message: String, level: MacaroniLoggingLevel, file: String, function: String, line: Int)
    func die() -> Never
}

public extension MacaroniLogger {
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    func errorAndDie(_ message: String, file: String = #file, function: String = #function, line: Int = #line) -> Never {
        log(message, level: .error, file: file, function: function, line: line)
        die()
    }
}

public final class SimpleMacaroniLogger: MacaroniLogger {
    public func log(_ message: String, level: MacaroniLoggingLevel, file: String, function: String, line: Int) {
        let levelString: String
        switch level {
            case .debug: levelString = "👣"
            case .error: levelString = "👿"
        }
        print("\(levelString) \(file.components(separatedBy: "/").last ?? "[unknown file]"):\(line) \(message)")
    }

    public func die() -> Never {
        fatalError("Macaroni is dead")
    }
}

public final class DisabledMacaroniLogger: MacaroniLogger {
    public func log(_ message: String, level: MacaroniLoggingLevel, file: String, function: String, line: Int) {}

    public func die() -> Never {
        fatalError("Macaroni is dead")
    }
}

enum Macaroni {
    static var logger: MacaroniLogger = SimpleMacaroniLogger()
}
