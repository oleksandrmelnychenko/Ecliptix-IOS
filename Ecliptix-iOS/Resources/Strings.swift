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
    
    enum ValidationErrors {
        enum PhoneNumber {
            static var mustStartWithCountryCode: String { "ValidationErrors.PhoneNumber.MustStartWithCountryCode".localized }
            static var containsNonDigits: String { "ValidationErrors.PhoneNumber.ContainsNonDigits".localized }
            static var incorrectLength: String { "ValidationErrors.PhoneNumber.IncorrectLength".localized }
            static var cannotBeEmpty: String { "ValidationErrors.PhoneNumber.CannotBeEmpty".localized }
        }
        
        enum SecureKey {
            static var required: String { "ValidationErrors.SecureKey.Required".localized }
            static var minLength: String { "ValidationErrors.SecureKey.MinLength".localized }
            static var maxLength: String { "ValidationErrors.SecureKey.MaxLength".localized }
            static var noUppercase: String { "ValidationErrors.SecureKey.NoUppercase".localized }
            static var noSpaces: String { "ValidationErrors.SecureKey.NoSpaces".localized }
            static var tooSimple: String { "ValidationErrors.SecureKey.TooSimple".localized }
            static var tooCommon: String { "ValidationErrors.SecureKey.TooCommon".localized }
            static var noDigit: String { "ValidationErrors.SecureKey.NoDigit".localized }
            static var sequentialPattern: String { "ValidationErrors.SecureKey.SequentialPattern".localized }
            static var repeatedChars: String { "ValidationErrors.SecureKey.RepeatedChars".localized }
            static var lacksDiversity: String { "ValidationErrors.SecureKey.LacksDiversity".localized }
            static var containsAppName: String { "ValidationErrors.SecureKey.ContainsAppName".localized }
            static var invalidCredentials: String { "ValidationErrors.SecureKey.InvalidCredentials".localized }
            static var nonEnglishLetters: String { "ValidationErrors.SecureKey.NonEnglishLetters".localized }
        }
    }
}
