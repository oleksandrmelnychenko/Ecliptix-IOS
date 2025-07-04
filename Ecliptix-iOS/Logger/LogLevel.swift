//
//  LogLevel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 04.07.2025.
//

enum LogLevel: Int, Comparable, Codable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3

    var short: String {
        switch self {
        case .debug: return "DBG"
        case .info: return "INF"
        case .warning: return "WRN"
        case .error: return "ERR"
        }
    }

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
