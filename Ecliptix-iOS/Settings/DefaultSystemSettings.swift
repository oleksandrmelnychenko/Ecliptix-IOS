//
//  AppSettings.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 11.06.2025.
//

public class DefaultSystemSettings {
    public var defaultTheme = "Light"
    public var environment = "Development"
    public var dataCenterConnectionString: String?
    public var domainName: String?
    public var culture: String
    
    init(
        defaultTheme: String = "Light",
        environment: String = "Development",
        dataCenterConnectionString: String? = nil,
        domainName: String? = nil,
        culture: String = "en-US"
    ) {
        self.defaultTheme = defaultTheme
        self.environment = environment
        self.dataCenterConnectionString = dataCenterConnectionString
        self.domainName = domainName
        self.culture = culture
    }
}
