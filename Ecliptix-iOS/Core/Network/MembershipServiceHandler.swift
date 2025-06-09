//
//  MembershipServiceHandler.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

import Foundation
import SwiftProtobuf
import GRPCCore

public class MembershipServiceHandler {
    private let verificationClient: Ecliptix_Proto_Membership_AuthVerificationServices.ClientProtocol
    
    init(verificationClient: Ecliptix_Proto_Membership_AuthVerificationServices.ClientProtocol) {
        self.verificationClient = verificationClient
    }
    
//    func getVerificationSessionIfExist(request: Ecliptix_Proto_CipherPayload) async throws -> AsyncStream<Ecliptix_Proto_CipherPayload> {
//        let call = try verificationClient.initiateVerification(request)
//        
//        return AsyncStream<Ecliptix_Proto_CipherPayload> { continuation in
//            
//            
//            for try await response in call.responses {
//                continuation.yield(response)
//            }
//            
//            continuation.finish()
//        }
//    }
    
//    func getVerificationSessionIfExist(
//            request: Ecliptix_Proto_CipherPayload
//        ) async throws -> AsyncThrowingStream<Ecliptix_Proto_CipherPayload, Error> {
//
//            let resonce = verificationClient.initiateVerification
//            
//            
//            
//            let resultt = verificationClient.int(
//                request: clientRequest) { responseStream in
//                return AsyncThrowingStream { continuation in
//                    Task {
//                        do {
//                            for try await response in responseStream.messages {
//                                continuation.yield(response)
//                            }
//                            continuation.finish()
//                        } catch {
//                            continuation.finish(throwing: error)
//                        }
//                    }
//                }
//            }
//        }
}
