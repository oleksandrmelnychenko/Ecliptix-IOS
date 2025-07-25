//
//  Strings.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 12.06.2025.
//

enum Strings {
    enum Welcome {
//        static var title: String { "Authentication.Registration.Welcome.title".localized }
//        static var description: String { "Authentication.Registration.Welcome.description".localized }
        
        static var signInButton: String { "Welcome.SignInButton".localized }
        static var createAccountButton: String { "Welcome.CreateAccountButton".localized }
    }
    
    enum Authentication {
        enum SignUp{
            enum PhoneVerification {
                static var title: String { "Authentication.SignUp.PhoneVerification.Title".localized }
                static var description: String { "Authentication.SignUp.PhoneVerification.Description".localized }
                
                static var mobilePlaceholder: String { "Authentication.SignUp.PhoneVerification.Watermark".localized }
                static var mobileHint: String { "Authentication.SignUp.PhoneVerification.Hint".localized }
                
                static var continueButton: String { "Authentication.SignUp.PhoneVerification.Button".localized }
                
                enum Error {
                    static var invalidFormat: String { "Authentication.SignUp.PhoneVerification.Error.InvalidFormat".localized }
                }
            }
            enum VerificationCodeEntry {
                static var title: String { "Authentication.SignUp.VerificationCodeEntry.Title".localized }
                static var description: String { "Authentication.SignUp.VerificationCodeEntry.Description".localized }
                
                static var codeHint: String { "Authentication.SignUp.VerificationCodeEntry.Hint".localized }
                
                static var expiration: String { "Authentication.SignUp.VerificationCodeEntry.Expiration".localized }
                
                enum Button {
                    static var verify: String { "Authentication.SignUp.VerificationCodeEntry.Button.Verify".localized }
                    static var resend: String { "Authentication.SignUp.VerificationCodeEntry.Button.Resend".localized }
                }
                
                enum Error {
                    static var invalidCode: String { "Authentication.SignUp.VerificationCodeEntry.Error.InvalidCode".localized }
                }
            }
            
            enum PasswordConfirmation {
                static var title: String { "Authentication.SignUp.PasswordConfirmation.Title".localized }
                static var description: String { "Authentication.SignUp.PasswordConfirmation.Description".localized }
                
                static var passwordHint: String { "Authentication.SignUp.PasswordConfirmation.PasswordHint".localized }
                static var verifyPasswordHint: String { "Authentication.SignUp.PasswordConfirmation.VerifyPasswordHint".localized }
                
                static var confirmButton: String { "Authentication.SignUp.PasswordConfirmation.Button".localized }
                
                enum Error {
                    static var passwordMismatch: String { "Authentication.SignUp.PasswordConfirmation.Error.PasswordMismatch".localized }
                }
            }
        }
        
        enum SignIn {
            static var title: String { "Authentication.SignIn.Title".localized }
            static var description: String { "Authentication.SignIn.Welcome".localized }
            
            static var mobilePlaceholder: String { "Authentication.SignIn.MobilePlaceholder".localized }
            static var mobileHint: String { "Authentication.SignIn.MobileHint".localized }
            
            static var passwordPlaceholder: String { "Authentication.SignIn.PasswordPlaceholder".localized }
            static var passwordHint: String { "Authentication.SignIn.PasswordHint".localized }
            
            static var accountRecovery: String { "Authentication.SignIn.AccountRecovery".localized }
            static var continueButton: String { "Authentication.SignIn.Continue".localized }
        }
    }
    
//    enum PhoneNumber {
//        static let title = "Authentication.Registration.phoneVerification.title".localized
//        static let description = "Authentication.Registration.phoneVerification.description".localized
//        
//        enum Buttons {
//            static let sendCode = "Authentication.Registration.phoneVerification.button".localized
//        }
//        
//        static let phoneFieldPlaceholder = "Phone number"
//        static let phoneFieldLabel = "Phone Number Field"
//        static let phoneFieldHint = "Enter your phone number here"
//        
//        enum Errors {
//            static let invalidFormat = "Authentication.Registration.phoneVerification.error.invalidFormat".localized
//        }
//    }
//    
//    enum VerificationCode {
//        static let title = "Verify your number"
//        static let description = "We have sent a code to your phone to verify your identity."
//        static let explanationText = "Enter the 6-digit code sent to"
//        
//        enum Buttons {
//            static let verifyCode = "Authentication.Registration.verificationCodeEntry.button.verify".localized
//            static let resendCode = "Authentication.Registration.verificationCodeEntry.button.resend".localized
//        }
//        
//        enum Errors {
//            static let invalidCode = "Authentication.Registration.verificationCodeEntry.error.invalidCode".localized
//        }
//    }
//    
//    enum PasswordSetup {
//        static let title = "Create a Password"
//        static let description = "Make sure it’s secure and something you’ll remember."
//        
//        static let passwordFieldLabel = "Password"
//        static let passwordFieldPlaceholder = "Enter password"
//        
//        static let confirmPasswordFieldLabel = "Confirm Password"
//        static let confirmPasswordFieldPlaceholder = "Confirm Password"
//        
//        enum Buttons {
//            static let next = "Next"
//        }
//        
//        enum Errors {
//            static let invalidPassword = "Password is invalid"
//        }
//    }
//    
//    enum PassPhaseRegister {
//        static let title = "Create a Pass phase"
//        static let description = "Make sure it’s something you’ll remember."
//        
//        enum Buttons {
//            static let submit = "Submit"
//        }
//        
//        enum Errors {
//            static let invalidPassPhase = "Pass phase is invalid"
//        }
//    }
    
//    enum SignIn {
//        static let title = "Sign in into account"
//        static let description = "Enter your email and password to sign in"
//    }
}
