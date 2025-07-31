//
//  SecureTextBuffer.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 30.07.2025.
//

import Foundation

final class SecureTextBuffer {
    private var secureHandle: SodiumSecureMemoryHandle
    private var isDisposed: Bool
    
    private(set) var length: Int
    
    init () {
        self.secureHandle = try! SodiumSecureMemoryHandle.allocate(length: 0).unwrap()
        self.length = 0
        
        self.isDisposed = false
    }
    
    func insert(index: Int, text: String) throws {
        if text.isEmpty {
            return
        }
        
        try self.modifyState(charIndex: index, removeCharCount: 0, insertChars: text)
    }
    
    func remove(index: Int, count: Int) throws {
        if count <= 0 {
            return
        }
        
        try self.modifyState(charIndex: index, removeCharCount: count, insertChars: "")
    }
    
    func withSecureBytes(_ action: (Data) -> Void) throws {
        guard !isDisposed else {
            throw EcliptixProtocolFailure.objectDisposed(String(describing: SecureTextBuffer.self))
        }

        guard !self.secureHandle.isInvalid, self.secureHandle.length > 0 else {
            action(Data())
            return
        }

        let length = self.secureHandle.length
        var buffer = Data(count: length)
        defer {
            buffer.removeAll()
        }

        do {
            _ = try buffer.withUnsafeMutableBytes { destPtr in
                self.secureHandle.read(into: destPtr)
            }.unwrap()
            
            action(buffer)
        } catch {
            print("Error reading secure handle: \(error)")
        }
    }
    
    private func modifyState(charIndex: Int, removeCharCount: Int, insertChars: String) throws {
        guard !self.isDisposed else {
            throw EcliptixProtocolFailure.objectDisposed(String(describing: SecureTextBuffer.self))
        }

        var oldBytes: Data?
        var newBytes: Data?
        var newHandle: SodiumSecureMemoryHandle?
        var success = false

        defer {
            if oldBytes != nil {
                oldBytes!.resetBytes(in: 0..<oldBytes!.count)
            }
            
            if newBytes != nil {
                newBytes!.resetBytes(in: 0..<newBytes!.count)
            }
            
            if !success {
                newHandle?.dispose()
            }
        }

        do {
            let oldByteLength = self.secureHandle.length
            var oldString = ""
            if oldByteLength > 0 {
                oldBytes = Data(count: oldByteLength)
                _ = try oldBytes!.withUnsafeMutableBytes { destPtr in
                    self.secureHandle.read(into: destPtr)
                }.unwrap()
                oldString = String(data: oldBytes!, encoding: .utf8) ?? ""
            }

            let clampedCharIndex = max(0, min(charIndex, self.length))
            let clampedRemoveCount = max(0, min(removeCharCount, self.length - clampedCharIndex))
            let insertData = insertChars.data(using: .utf8)!

            let startByte: Int
            let endByte: Int

            if !oldString.isEmpty {
                let start = oldString.index(oldString.startIndex, offsetBy: clampedCharIndex)
                let end = oldString.index(oldString.startIndex, offsetBy: clampedCharIndex + clampedRemoveCount)
                startByte = oldString[..<start].lengthOfBytes(using: .utf8)
                endByte = oldString[..<end].lengthOfBytes(using: .utf8)
            } else {
                startByte = 0
                endByte = 0
            }

            var newData = oldBytes ?? Data()
            newData.replaceSubrange(startByte..<endByte, with: insertData)

            newHandle = try SodiumSecureMemoryHandle.allocate(length: newData.count).unwrap()
            _ = try newData.withUnsafeBytes { bufferPointer in
                newHandle!.write(data: bufferPointer)
            }.unwrap()

            self.secureHandle.dispose()
            self.secureHandle = newHandle!
            self.length = self.length - clampedRemoveCount + insertChars.count
            success = true
        }
    }
}
