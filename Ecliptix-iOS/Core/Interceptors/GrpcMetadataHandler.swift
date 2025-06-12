//
//  GrpcMetadataHandler.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 11.06.2025.
//

import Foundation
import NIOHPACK
import GRPC


public class GrpcMetadataHandler {
    private static let requestIdKey = "request-id";
    private static let dateTimeKey = "request-date";
    private static let localIpAddressKey = "local-ip-address";
    private static let publicIpAddressKey = "public-ip-address";
    private static let localeKey = "lang";
    private static let linkIdKey = "fetch-link";
    private static let applicationInstanceIdKey = "application-identifier";
    private static let appDeviceId = "d-identifier";
    private static let keyExchangeContextTypeKey = "oiwfT6c5kOQsZozxhTBg";
    private static let keyExchangeContextTypeValue = "JmTGdGilMka07zyg5hz6Q";
    private static let connectionContextId = "c-context-id";
    private static let operationContextId = "o-context-id";
 
    public static func generateMetadata(appInstanceId: UUID, appDeviceId: UUID, operationId: UUID = UUID.init()) -> HPACKHeaders {
        var headers = HPACKHeaders()
        headers.add(name: Self.requestIdKey, value: UUID().uuidString)
        
        
        headers.add(name: Self.requestIdKey, value: UUID().uuidString)
        headers.add(name: Self.dateTimeKey, value: ISO8601DateFormatter().string(from: Date()))
        headers.add(name: Self.localIpAddressKey, value: getLocalIpAddress())
        headers.add(name: Self.publicIpAddressKey, value: getPublicIpAddress())
        headers.add(name: Self.localeKey, value: normalizedLocaleIdentifier())
        headers.add(name: Self.linkIdKey, value: "fetch-link-placeholder")
        headers.add(name: Self.applicationInstanceIdKey, value: appInstanceId.uuidString)
        headers.add(name: Self.appDeviceId, value: appDeviceId.uuidString)
        headers.add(name: Self.keyExchangeContextTypeKey, value: keyExchangeContextTypeValue)
        headers.add(name: Self.connectionContextId, value: String(describing: Ecliptix_Proto_PubKeyExchangeType.dataCenterEphemeralConnect.self))
        headers.add(name: Self.operationContextId, value: "")
        
        return headers
    }
    
    private static func getLocalIpAddress() -> String {
        return "127.0.0.1"
    }
    
    private static func getPublicIpAddress() -> String {
        return "192.168.1.1"
    }
    
    private static func normalizedLocaleIdentifier(locale: Locale = .current) -> String {
        if #available(iOS 16.0, *) {
            if let lang = locale.language.languageCode?.identifier,
               let reg = locale.region?.identifier {
                return "\(lang)_\(reg)"
            }
        } else {
            if let lang = locale.languageCode,
               let reg = locale.regionCode {
                return "\(lang)_\(reg)"
            }
        }
        return "en_US"
    }

}
