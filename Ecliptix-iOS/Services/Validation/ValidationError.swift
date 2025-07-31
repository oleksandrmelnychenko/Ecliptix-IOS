//
//  ValidationError.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 17.06.2025.
//

import Foundation

protocol ValidationError: Identifiable, Hashable {
    var messageKey: String { get }
    var args: [CVarArg] { get }
}

extension ValidationError {
    var id: String { messageKey + args.map { "\($0)" }.joined(separator: "_") }

    var message: String {
        String(format: NSLocalizedString(messageKey, comment: ""), arguments: args)
    }
}
