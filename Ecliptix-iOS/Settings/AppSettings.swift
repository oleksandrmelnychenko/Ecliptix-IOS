//
//  AppSettings.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 11.06.2025.
//

public class AppSettings {
    public var defaultTheme = "Light"
    public var environment = "Development"
    public var localHostUrl: String?
    public var cloudHostUrl: String?
    public var domainName: String?
    
    public var localization = LocalizationSettings()
}
