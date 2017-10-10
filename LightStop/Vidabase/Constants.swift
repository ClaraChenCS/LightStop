//
//  Constants.swift
//  Kamptive
//
//  Created by Carlos Martinez on 3/8/16.
//  Copyright © 2016 Carlos Martinez. All rights reserved.
//

import UIKit

// MARK: - Enums
enum AuthenticationOptions : String {
    case Login, Signup
}

enum PasswordOptions : String {
    case Reset, Change
}

// MARK: - Constants
struct Constant {
    
    struct ViewControllersID {
        static let ListViewController = "ListViewController"
        static let MapViewController = "MapViewController"
    }
    
    struct SearchResultsButtonTitle {
        static let List = "List"
        static let Map = "Map"
    }
    
    struct Textfield {
        static let NoCharacters = 0
        static let EmptyString = ""
        static let MaxEmailSize = 45
        static let MaxPasswordSize = 30
        static let MaxPinSize = 4
    }
    
    struct Keyboard {
        static let HeightFractioner:CGFloat = 0.5
        static let FullHeight:CGFloat = 1.0
        static let CeroTimeInterval:Double = 0
    }
    
    struct Validation {
        static let EmailError = "Invalid email"
    }
    
    struct Segue {
        static let AgreementPrivacy = "AuthenticationToAgreementPrivacySegue"
    }
    
    struct Response {
        static let StatusSuccess = "SUCCESS"
        static let ReturnStatus = "returnStatus"
        static let TokenID = "tokenID"
        static let CustomerID = "customerID"
        static let Email = "email"
        static let SearchCities = "searchCities"
        static let City = "city"
        static let State = "state"

    }
    
    struct Facebook {
        struct Permission {
            static let PublicProfile = "public_profile"
            static let ErrorTitle = "Google Permission Error"
        }
    }
    
    struct Entity {
        static let User = "User"
    }
    
    struct Attribute {
        static let Email = "email"
    }
    
    struct Predicate {
        static let Email = "email == %@"
    }
    
    struct CharactersNotAllowedIn {
        static let Email = "=+/\\{}[](),*&^%$#!~`<>?|;:'\""
    }
    
    struct AuthenticationButtonTitle {
        static let Login = "Log In"
        static let Signup = "Sign Up"
    }
    
    struct PasswordActionsButtonTitle {
        static let Reset = "Reset Password"
        static let Change = "Change Password"
    }
    
    struct PasswordActionsDescription {
        static let Reset = "Please enter your email address and we will send you the instructions to reset you password."
        static let Change = "Please enter your Email Address, Pin and New Password."
    }
    
    struct AuthenticationToggle {
        static let Login = "Already have an account? Log In"
        static let Signup = "Sign Up"
    }
    
    struct PasswordActionsToggle {
        static let Reset = "Change Password with Pin"
        static let Change = "Request Password Reset"
    }
    
    struct DocumentTag {
        static let UserAgreement = 1001
        static let PrivacyPolicy = 1002
    }
    
    struct AnimationTime {
        static let Default = 0.3
        static let NoAmination = 0.0
    }
    
    struct BorderWidthFor {
        static let Success:CGFloat = 0.1
        static let Error:CGFloat = 0.5
        static let Default:CGFloat = 0.0
    }
    
    struct MoveKeyboard {
        static let MINIMUM_SCROLL_FRACTION : CGFloat = 0.2;
        static let MAXIMUM_SCROLL_FRACTION : CGFloat = 0.8;
    }
    
    struct API {
        struct Development {
            static let BaseURL = "http://www.uHype.com:8080/MainPage"
        }
        struct Production {
            static let BaseURL = "http://www.uHype.com:8080/MainPage"
            static let UserAgreementURL = "http://www.uHype.com/company/terms"
            static let PrivacyPolicyURL = "http://www.uHype.com/company/privacy"
        }
    }
    
    struct AutoCompleteTextField {
        static let MaximumAutoCompleteCount = 20
        static let TextFont = UIFont(name: "HelveticaNeue-Bold", size: 12.0)!
        struct AutoCompleteTableView {
            static let CellBackgroundColor = Helper.UIColorFromHex(0xFAFAFA)
            static let TextColor = Helper.UIColorFromHex(0x808080)
            static let TextFont = UIFont(name: "HelveticaNeue-Light", size: 12.0)!
            static let CellHeight:CGFloat = 35.0
            static let MaximumTableHeight:CGFloat = 200.0
        }
    }
    
    // MARK: UI
    struct UI {
        static let LoginColorTop = UIColor(red: 0.345, green: 0.839, blue: 0.988, alpha: 1.0).cgColor
        static let LoginColorBottom = UIColor(red: 0.023, green: 0.569, blue: 0.910, alpha: 1.0).cgColor
        static let GreyColor = UIColor(red: 0.702, green: 0.863, blue: 0.929, alpha:1.0)
        static let BlueColor = UIColor(red: 0.0, green:0.502, blue:0.839, alpha: 1.0)
        static let StatusBarHeight : CGFloat = 22.0
    }
    
    // MARK: Selectors
    struct Selectors {
        static let KeyboardWillShow = "keyboardWillShow:"
        static let KeyboardWillHide = "keyboardWillHide:"
        static let KeyboardDidShow = "keyboardDidShow:"
        static let KeyboardDidHide = "keyboardDidHide:"
    }
}
