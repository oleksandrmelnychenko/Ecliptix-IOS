//
//  Strings.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 12.06.2025.
//

enum Strings {
    enum Welcome {
        static let title = "World App"
        static let description = "The wallet designed to make digital ID and global finance simple for all."
        
        enum NavigationCard_Main {
            static let title = "New account"
            static let subtitle = "Create new Worldcoin account"
        }
        enum NavigationCard_Alternative {
            static let title = "Existing account"
            static let subtitle = "Restore account from a backup"
        }
    }
    
    enum PhoneNumber {
        static let title = "Authentication.Registration.phoneVerification.title".localized
        static let description = "Authentication.Registration.phoneVerification.description".localized
        
        enum Buttons {
            static let sendCode = "Authentication.Registration.phoneVerification.button".localized
        }
        
        static let countryPickerTitle = "Select Country"
        static let countryPickerCancelButtonTitle = "Cancel"
        
        static let phoneFieldPlaceholder = "Phone number"
        static let phoneFieldLabel = "Phone Number Field"
        static let phoneFieldHint = "Enter your phone number here"
        
        enum Errors {
            static let invalidFormat = "Authentication.Registration.phoneVerification.error.invalidFormat".localized
        }
    }
    
    enum VerificationCode {
        static let title = "Verify your number"
        static let description = "We have sent a code to your phone to verify your identity."
        static let explanationText = "Enter the 6-digit code sent to"
        
        enum Buttons {
            static let verifyCode = "Authentication.Registration.verificationCodeEntry.button.verify".localized
            static let resendCode = "Authentication.Registration.verificationCodeEntry.button.resend".localized
        }
        
        enum Errors {
            static let invalidCode = "Authentication.Registration.verificationCodeEntry.error.invalidCode".localized
        }
    }
    
    enum PasswordSetup {
        static let title = "Create a Password"
        static let description = "Make sure it’s secure and something you’ll remember."
        
        static let passwordFieldLabel = "Password"
        static let passwordFieldPlaceholder = "Enter password"
        
        static let confirmPasswordFieldLabel = "Confirm Password"
        static let confirmPasswordFieldPlaceholder = "Confirm Password"
        
        enum Buttons {
            static let next = "Next"
        }
        
        enum Errors {
            static let invalidPassword = "Password is invalid"
        }
    }
    
    enum PassPhaseRegister {
        static let title = "Create a Pass phase"
        static let description = "Make sure it’s something you’ll remember."
        
        enum Buttons {
            static let submit = "Submit"
        }
        
        enum Errors {
            static let invalidPassPhase = "Pass phase is invalid"
        }
    }
    
    enum SignIn {
        static let title = "Sign in into account"
        static let description = "Sign in to join conversation."
    }
}
