//
//  NetworkEventsProtocol.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 14.07.2025.
//
import Combine

protocol NetworkEventsProtocol {
    var networkStatusChanged: AnyPublisher<NetworkStatusChangedEvent, Never> { get }
    func initiateChangeState(_ message: NetworkStatusChangedEvent)
}
