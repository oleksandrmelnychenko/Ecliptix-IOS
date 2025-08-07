//
//  SessionExecutor.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 19.06.2025.
//

import Foundation

enum AuthenticationUserState {
    case verifiedOtp
    case confirmedPasswords
    case passphraseSet
    
    case notInitialized
}

final class ApplicationInitializer: ApplicationInitializerProtocol {
    private let networkProvider: NetworkProvider
    private let secureStorageProvider: SecureStorageProviderProtocol
    private let localizationService: LocalizationService
    private let systemEvents: SystemEventsProtocol
    
    init(
        networkProvider: NetworkProvider,
        secureStorageProvider: SecureStorageProviderProtocol,
        localizationService: LocalizationService,
        systemEvents: SystemEventsProtocol
    ) {
        self.networkProvider = networkProvider
        self.secureStorageProvider = secureStorageProvider
        self.localizationService = localizationService
        self.systemEvents = systemEvents
    }
    
    func initializeAsync(defaultSystemSettings: DefaultSystemSettings) async -> Result<Unit, InternalValidationFailure> {
        
        do {
            self.systemEvents.publish(.new(.initializing))
            
            let settingsResult = self.secureStorageProvider.initApplicationInstanceSettings()
            guard settingsResult.isOk else {
                Logger.error("Failed to get or create application instance settings: \(try settingsResult.unwrapErr())", category: "AppInit")
                self.systemEvents.publish(.new(.fatalError))
                return .failure(.internalServiceApi("Failed to get or create application instance settings", inner: (try settingsResult.unwrapErr())))
            }
            
            let result = try settingsResult.unwrap()
            
//            try await Task.sleep(nanoseconds: 60 * 1_000_000_000)
                    
            let recoveredSession = await networkProvider.recoverSession(settings: result.settings, shouldBeRecovered: !result.isNewInstance)
            guard recoveredSession.isOk else {
                Logger.error("Error during recovering session: \(try recoveredSession.unwrapErr())", category: "AppInit")
                return .failure(.internalServiceApi("Error during recovering session", inner: (try recoveredSession.unwrapErr())))
            }
            
            Logger.info("Application initialized successfully", category: "AppInit")
            
            self.systemEvents.publish(.new(.running))
            return .success(.value)
        } catch {
            Logger.error("An unhandled error occurred during application initialization: \(error)", category: "AppInit")
            return .failure(.unknown("An unhandled error occurred during application initialization", inner: error))
        }
    }
    
    func retriveUserState() async -> Result<AuthenticationUserState, InternalValidationFailure> {
        return AppSettingsService.shared.getSettings()
            .mapInternalServiceApiFailure()
            .flatMap { settings in
                let authenticationUserState = combineAuthenticationUserState(with: settings.membership.creationStatus)
                
                return .success(authenticationUserState)
            }
    }
    
    private func combineAuthenticationUserState(
        with creationStatus: Ecliptix_Proto_Membership_Membership.CreationStatus
    ) -> AuthenticationUserState {
        switch creationStatus {
        case .otpVerified: return .verifiedOtp
        case .secureKeySet: return .confirmedPasswords
        case .passphraseSet: return .passphraseSet
        case .UNRECOGNIZED(_): return .notInitialized
        }
    }
    
    

}
