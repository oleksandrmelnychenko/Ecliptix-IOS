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

    static func Try(_ block: () throws -> Success) -> Result<Success, Failure> {
        do {
            let value = try block()
            return .success(value)
        } catch let error as Failure {
            return .failure(error)
        } catch {
            fatalError("Unexpected error type: \(error)")
        }
    }
    
    static func Try(
        _ block: () throws -> Success,
        cleanup: () -> Void
    ) -> Result<Success, Failure> {
        defer {
            cleanup()
        }
        
        do {
            let value = try block()
            return .success(value)
        } catch let error as Failure {
            return .failure(error)
        } catch {
            fatalError("Unexpected error type: \(error)")
        }
    }


    static func TryAsync(_ block: @escaping () async throws -> Success) async -> Result<Success, Failure> {
        do {
            let value = try await block()
            return .success(value)
        } catch let error as Failure {
            return .failure(error)
        } catch {
            fatalError("Unexpected error type: \(error)")
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

    var isOk: Bool {
        if case .success = self { return true }
        return false
    }

    var isErr: Bool {
        return !isOk
    }
}


