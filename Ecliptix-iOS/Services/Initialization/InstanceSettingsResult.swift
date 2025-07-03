//
//  InstanceSettingsResult.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 03.07.2025.
//


import Foundation

struct InstanceSettingsResult {
    let settings: Ecliptix_Proto_AppDevice_ApplicationInstanceSettings
    let isNewInstance: Bool
}