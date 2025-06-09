//
//  NetworkController.swift
//  Ecliptix-iOS-test
//
//  Created by Oleksandr Melnechenko on 06.06.2025.
//

//import Foundation
//import SwiftProtobuf
//
//final class NetworkController {
//    private var connections: [UInt32: EcliptixConnectionContext] = [:]
//    private let networkServiceManager: NetworkServiceManager
//    
//    init(networkServiceManager: NetworkServiceManager) {
//        self.networkServiceManager = networkServiceManager
//    }
//    
//    func createEcliptixConnectionContext(connectId: UInt32, oneTimeKeyCount: UInt32, pubKeyExchangeType: Ecliptix_Proto_PubKeyExchangeType) {
//        do {
//            let identityKeys = try EcliptixSystemIdentityKeys.create(oneTimeKeyCount: oneTimeKeyCount).unwrap()
//            let protocolSystem = EcliptixProtocolSystem(ecliptixSystemIdentityKeys: identityKeys)
//            let context = EcliptixConnectionContext(pubKeyExchangeType: pubKeyExchangeType, ecliptixProtocolSystem: protocolSystem)
//            connections[connectId] = context
//        } catch {
//            
//        }
//    }
//    
//    func executeServiceAction(
//       connectId: UInt32,
//       serviceAction: RcpServiceAction,
//       plainBuffer: Data,
//       flowType: ServiceFlowType,
//       onSuccessCallback: @escaping (Data) async -> Result<Unit, EcliptixProtocolFailure>,
//       token: CancellationToken? = nil
//    ) async -> Result<Unit, EcliptixProtocolFailure> {
//        guard let context = connections[connectId] else {
//            return .failure(.generic("Connection not found"))
//        }
//        
//        do {
//            let protocolSystem = context.ecliptixProtocolSystem
//            let pubKeyExchangeType = context.pubKeyExchangeType
//            
//            let outboundPayload = try protocolSystem.produceOutboundMessage(connectId: connectId, exchangeType: pubKeyExchangeType, plainPayload: plainBuffer)
//            
//            let request = ServiceRequest.new(actionType: flowType, rcpServiceMethod: serviceAction, payload: outboundPayload, encryptedChunls: [])
//            let invokeResult = try await networkServiceManager.invokeService(request: request, token: token)
//        } catch {
//            
//        }
//        
//       
//    }
//}
