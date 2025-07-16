//
//  Strings.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 12.06.2025.
//

enum Strings {
//    enum Welcome {
//        static var title: String { "Authentication.Registration.Welcome.title".localized }
//        static var description: String { "Authentication.Registration.Welcome.description".localized }
//        
//        enum NavigationCard_Main {
//            static var title: String { "Authentication.Registration.Welcome.MainCard.title".localized }
//            static var subtitle: String { "Authentication.Registration.Welcome.MainCard.subtitle".localized }
//        }
//
//        enum NavigationCard_Alternative {
//            static var title: String { "Authentication.Registration.Welcome.AlternativeCard.title".localized }
//            static var subtitle: String { "Authentication.Registration.Welcome.AlternativeCard.subtitle".localized }
//        }
//    }
    
    enum PhoneNumber {
        static let title = "Authentication.Registration.phoneVerification.title".localized
        static let description = "Authentication.Registration.phoneVerification.description".localized
        
        enum Buttons {
            static let sendCode = "Authentication.Registration.phoneVerification.button".localized
        }
        
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
    
//    enum SignIn {
//        static let title = "Sign in into account"
//        static let description = "Enter your email and password to sign in"
//    }
}
