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
    
    func getVerificationSessionIfExist(
        request: Ecliptix_Proto_CipherPayload
    ) async throws -> AsyncThrowingStream<Ecliptix_Proto_CipherPayload, Error> {
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Call the async initiateVerification with the streaming response handler closure
                    _ = try await verificationClient.initiateVerification(request) { streamingResponse in
                        // This closure is async and called once the streaming response is ready
                        
                        do {
                            // Iterate over the stream asynchronously
                            for try await message in streamingResponse.messages {
                                continuation.yield(message)
                            }
                            continuation.finish()
                        } catch {
                            continuation.finish(throwing: error)
                        }
                        
                        // Return some dummy value because the closure expects a return value of generic Result type
                        // But in this case, we just want to yield values via continuation and finish.
                        // If the closure needs a specific type, adjust accordingly.
                        return ()
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

}
