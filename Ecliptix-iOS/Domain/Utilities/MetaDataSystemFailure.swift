//
//  MetaDataSystemFailure.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 22.05.2025.
//

import Foundation

enum MetaDataSystemFailureType {
    case requiredComponentNotFound
}

class MetaDataSystemFailure: CustomStringConvertible {
    let type: MetaDataSystemFailureType
    let message: String?
    let innerError: Error?

    private init(type: MetaDataSystemFailureType, message: String?, innerError: Error? = nil) {
        self.type = type
        self.message = message
        self.innerError = innerError
    }

    static func componentNotFound(details: String? = nil) -> MetaDataSystemFailure {
        return MetaDataSystemFailure(type: .requiredComponentNotFound, message: details)
    }
    
    var description: String {
        return "MetaDataSystemFailure(type: \(type), message: \(message ?? "nil"), innerError: \(innerError?.localizedDescription ?? "nil"))"
    }
}
