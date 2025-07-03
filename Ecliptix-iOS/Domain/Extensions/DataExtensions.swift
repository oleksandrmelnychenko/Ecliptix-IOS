//
//  DataExtensions.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 02.07.2025.
//

import Foundation

extension Data {
    mutating func swapBytes(at i: Int, and j: Int) {
        guard i != j, i >= 0, j >= 0, i < count, j < count else { return }

        withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) in
            guard let base = pointer.baseAddress else { return }

            let ptr = base.assumingMemoryBound(to: UInt8.self)
            swap(&ptr[i], &ptr[j])
        }
    }
}
