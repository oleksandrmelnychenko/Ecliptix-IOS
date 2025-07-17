//
//  Logger.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 04.07.2025.
//

import Foundation

final class Logger {
    // MARK: - Shared instance (Singleton)
    static let shared = Logger()

    // MARK: - Static API
    static func configure(minimumLevel: LogLevel, maxFileSize: UInt64, retainedFileCountLimit: Int) {
        shared.configure(minimumLevel: minimumLevel, maxFileSize: maxFileSize, retainedFileCountLimit: retainedFileCountLimit)
    }

    static var overrides: [String: LogLevel] {
        get { shared.overrides }
        set { shared.overrides = newValue }
    }

    static func debug(_ msg: String, category: String? = nil)   { shared.debug(msg, category: category) }
    static func info(_ msg: String, category: String? = nil)    { shared.info(msg, category: category) }
    static func warning(_ msg: String, category: String? = nil) { shared.warning(msg, category: category) }
    static func error(_ msg: String, category: String? = nil)   { shared.error(msg, category: category) }

    // MARK: - Configuration
    private(set) var minimumLevel: LogLevel = .info
    private(set) var retainedFileCountLimit: Int = 7
    private(set) var maxFileSize: UInt64 = 10_000_000
    var overrides: [String: LogLevel] = [:]

    private let queue = DispatchQueue(label: "logger.queue", qos: .background)

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private let fileNameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private var logDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let logsDir = appSupport.appendingPathComponent("Storage/logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        return logsDir
    }

    private init() {
        cleanupOldLogs()
    }

    func configure(minimumLevel: LogLevel, maxFileSize: UInt64, retainedFileCountLimit: Int) {
        self.minimumLevel = minimumLevel
        self.maxFileSize = maxFileSize
        self.retainedFileCountLimit = retainedFileCountLimit
        cleanupOldLogs()
    }

    // MARK: - Logging

    func log(_ level: LogLevel, _ message: String, category: String? = nil) {
        queue.async {
            guard self.shouldLog(level: level, category: category) else { return }

            let timestamp = self.dateFormatter.string(from: Date())
            let line = "[\(timestamp) \(level.short)]" + (category != nil ? " [\(category!)]" : "") + " \(message)\n"

            self.write(line: line)
        }
    }

    func debug(_ msg: String, category: String? = nil)   { log(.debug, msg, category: category) }
    func info(_ msg: String, category: String? = nil)    { log(.info, msg, category: category) }
    func warning(_ msg: String, category: String? = nil) { log(.warning, msg, category: category) }
    func error(_ msg: String, category: String? = nil)   { log(.error, msg, category: category) }

    private func shouldLog(level: LogLevel, category: String?) -> Bool {
        if let cat = category, let override = overrides[cat] {
            return level >= override
        }
        return level >= minimumLevel
    }

    // MARK: - File I/O

    private func write(line: String) {
        let data = Data(line.utf8)
        let today = fileNameDateFormatter.string(from: Date())

        var fileURL = logDirectory.appendingPathComponent("ecliptix-\(today).log")

        if isFileTooLarge(fileURL) {
            var index = 1
            repeat {
                let newFileName = "ecliptix-\(today)-\(index).log"
                let newURL = logDirectory.appendingPathComponent(newFileName)
                if !FileManager.default.fileExists(atPath: newURL.path) || !isFileTooLarge(newURL) {
                    fileURL = newURL
                    break
                }
                index += 1
            } while index < 100
        }

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }

        if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
            _ = try? fileHandle.seekToEnd()
            fileHandle.write(data)
            try? fileHandle.close()
        }
    }

    private func isFileTooLarge(_ file: URL) -> Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
              let fileSize = attributes[.size] as? UInt64 else {
            return false
        }
        return fileSize >= maxFileSize
    }

    func cleanupOldLogs() {
        queue.async {
            let files = (try? FileManager.default.contentsOfDirectory(at: self.logDirectory, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)) ?? []

            let logFiles = files.filter { $0.lastPathComponent.hasPrefix("ecliptix-") && $0.pathExtension == "log" }
            let sorted = logFiles.sorted {
                let d1 = try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate ?? .distantPast
                let d2 = try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? .distantPast
                return d1! < d2!
            }

            let toRemove = sorted.dropLast(self.retainedFileCountLimit)
            for file in toRemove {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
}

