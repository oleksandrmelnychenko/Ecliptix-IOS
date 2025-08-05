//
//  Result.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 22.05.2025.
//

import Foundation

extension Result {
    
    func unwrap() throws -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    func unwrapErr() throws -> Failure {
        switch self {
        case .failure(let error):
            return error
        case .success:
            throw NSError(domain: "ResultErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot unwrap a Success result"])
        }
    }
    
    static func fromValue(_ value: Success?, _ errorWhenNull: Failure) -> Result<Success, Failure> {
        return switch value {
            case .some(let val):
                .success(val)
            case .none:
                .failure(errorWhenNull)
        }
    }
    
    static func validate(_ value: Success, predicate: (Success) -> Bool, error: Failure) -> Result<Success, Failure> {
        return predicate(value) ? .success(value) : .failure(error)
    }

    static func Try(
        _ block: () throws -> Success,
        errorMapper: (Error) -> Failure
    ) -> Result<Success, Failure> {
        do {
            let value = try block()
            return .success(value)
        } catch {
            return .failure(errorMapper(error))
        }
    }
    
    static func Try(
        _ block: () throws -> Success,
        errorMapper: (Error) -> Failure,
        cleanup: () -> Void
    ) -> Result<Success, Failure> {
        defer {
            cleanup()
        }
        
        do {
            let value = try block()
            return .success(value)
        } catch {
            return .failure(errorMapper(error))
        }
    }


    static func TryAsync(
        _ block: @escaping () async throws -> Success,
        errorMapper: (Error) -> Failure
    ) async -> Result<Success, Failure> {
        do {
            let value = try await block()
            return .success(value)
        } catch {
            return .failure(errorMapper(error))
        }
    }

    func Match<T>(
        onSuccess: (Success) throws -> T,
        onFailure: (Failure) throws -> T
    ) rethrows -> T {
        switch self {
        case .success(let value):
            return try onSuccess(value)
        case .failure(let error):
            return try onFailure(error)
        }
    }
    
    func MatchAsync<T>(
        onSuccessAsync: @escaping (Success) async throws -> T,
        onFailureAsync: @escaping (Failure) async throws -> T
    ) async rethrows -> T {
        switch self {
        case .success(let value):
            return try await onSuccessAsync(value)
        case .failure(let error):
            return try await onFailureAsync(error)
        }
    }
    
    func flatMapAsync<T>(
        _ transform: @escaping (Success) async -> Result<T, Failure>
    ) async -> Result<T, Failure> {
        switch self {
        case .success(let value):
            return await transform(value)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func flatMapErrorAsync(
        _ transform: @escaping (Failure) async -> Result<Success, Failure>
    ) async -> Result<Success, Failure> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            return await transform(error)
        }
    }

    var isOk: Bool {
        if case .success = self { return true }
        return false
    }

    var isErr: Bool {
        return !isOk
    }
}


