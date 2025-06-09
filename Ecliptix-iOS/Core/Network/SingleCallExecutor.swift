//
//  SingleCallExecutor.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

public final class SingleCallExecutor {
    let membershipServicesClient: Ecliptix_Proto_Membership_MembershipServices.ClientProtocol
    let appDeviceServiceActionsClient: Ecliptix_Proto_AppDevice_AppDeviceServiceActions.ClientProtocol
    let authenticationServicesClient: Ecliptix_Proto_Membership_AuthVerificationServices.ClientProtocol
    
    init(membershipServicesClient: Ecliptix_Proto_Membership_MembershipServices.ClientProtocol, appDeviceServiceActionsClient: Ecliptix_Proto_AppDevice_AppDeviceServiceActions.ClientProtocol, authenticationServicesClient: Ecliptix_Proto_Membership_AuthVerificationServices.ClientProtocol) {
        self.membershipServicesClient = membershipServicesClient
        self.appDeviceServiceActionsClient = appDeviceServiceActionsClient
        self.authenticationServicesClient = authenticationServicesClient
    }
}
