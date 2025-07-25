//
//  PassPhaseViewModel.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 16.06.2025.
//

import Foundation
import SwiftUI

@MainActor
final class PassPhaseRegisterViewModel: ObservableObject {
    @Published private(set) var pin: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let maxDigits = 4
    
    var passPhrase: String { pin.joined() }
    var isReady: Bool { pin.count == maxDigits }
    
    func append(_ digit: String) {
        guard pin.count < maxDigits else { return }
        pin.append(digit)
    }
    
    func removeLast() {
        guard !pin.isEmpty else { return }
        pin.removeLast()
    }
    
    func getPassPhaseFromFaceId() {
        
    }
    
    func submitPassPhase() {
        guard isReady else { return }
        
        errorMessage = nil
        isLoading = true
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                self.isLoading = false
                
                if passPhrase == "1234" {
                }
                else {
                }
            }
        }
    }
}
