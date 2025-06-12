//
//  MembershipServiceHandler.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

import Foundation
import GRPC
import SwiftProtobuf

public class MembershipServiceHandler {
    private let verificationClient: Ecliptix_Proto_Membership_AuthVerificationServicesAsyncClient

    init(verificationClient: Ecliptix_Proto_Membership_AuthVerificationServicesAsyncClient) {
        self.verificationClient = verificationClient
    }

    func getVerificationSessionIfExist(
        request: Ecliptix_Proto_CipherPayload
    ) -> AsyncThrowingStream<Ecliptix_Proto_CipherPayload, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let stream = verificationClient.initiateVerification(request)
                    for try await response in stream {
                        continuation.yield(response)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
