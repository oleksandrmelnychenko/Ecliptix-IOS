//
//  Google_Protobuf_TimestampExtension.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 02.07.2025.
//

import SwiftProtobuf
import Foundation

extension Google_Protobuf_Timestamp {
    func toDate() -> Date {
        return Date(timeIntervalSince1970: TimeInterval(self.seconds) + TimeInterval(self.nanos) / 1_000_000_000)
    }
    
    static func fromDate(date: Date) -> Google_Protobuf_Timestamp {
        var timestamp = Google_Protobuf_Timestamp()
        let seconds = Int64(date.timeIntervalSince1970)
        let nanos = Int32((date.timeIntervalSince1970 - Double(seconds)) * 1_000_000_000)
        timestamp.seconds = seconds
        timestamp.nanos = nanos
        return timestamp
    }
}
