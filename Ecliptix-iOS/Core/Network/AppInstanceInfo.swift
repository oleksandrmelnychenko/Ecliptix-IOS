//
//  AppInstanceInfo.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

import Foundation

actor AppInstanceInfo {
    let appInstanceId: UUID = UUID(uuidString: "9147df66-46bd-4bae-87df-6646bd5bae4c")!
    let deviceId: UUID = UUID(uuidString: "4c5aaf82-a0c4-40e5-9aaf-82a0c470e53f")!
    
    /// Server registration.
    var systemDeviceIdentifier: UUID?
}

extension AppInstanceInfo {
    func setSystemDeviceIdentifier(_ id: UUID) {
        self.systemDeviceIdentifier = id
    }
}
