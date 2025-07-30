//
//  SecureStorageProviderProtocol.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 02.07.2025.
//

import Foundation

protocol SecureStorageProviderProtocol {
    
    func initApplicationInstanceSettings() -> Result<InstanceSettingsResult, InternalServiceApiFailure>
    func store(key: String, data: Data) -> Result<Unit, InternalServiceApiFailure>
    func tryGetByKey(key: String) -> Result<Data?, InternalServiceApiFailure>
    func delete(key: String) -> Result<Unit, InternalServiceApiFailure>
}
