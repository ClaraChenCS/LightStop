//
//  ForgotPasswordViewController.swift
//  Kamptive
//
//  Created by Carlos Martinez on 3/20/16.
//  Copyright © 2016 Carlos Martinez. All rights reserved.
//

import UIKit
import Alamofire        // Linked Framework - Requires: iOS 8.0+, Xcode 7.2+
import SwiftValidator   // Linked Framework - Requires: iOS 8.1+
import Firebase         // Backend service SDK library

// MARK: - Class Implementation
class ForgotPasswordViewController: UIViewController {
    
    // MARK: Properties
    var textFieldsArray = [UITextField]()            // Array to hold reference to all textfields in view
    var textFieldErrorLabelsArray = [UILabel]()  // Array to hold references to all textfield error labels
    var validator = Validator()         // Textfield Validator Object
    var animateDistance = CGFloat()     // Animation Distance for Keyboard
    var keyboardOnScreen = false        // Flag for Keyboard: On Screen or Not
    var activeField: UITextField?       // Hold active textfield reference
    var firebaseRef:Firebase?           // Firebase database reference
    
    // MARK: IBOutlets
    @IBOutlet weak var emailTextField: UITextField!                 //
    @IBOutlet weak var emailErrorLabel: UILabel!                    //
    @IBOutlet weak var resetChangePasswordButton: UIButton!         //
    @IBOutlet weak var actionDescriptionLabel: UILabel!             //
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Note: "Pin Text Field" and "New Password Text Field" are hidden at     *
        *        runtime using the "User Defined Runtime Attributes" in Interface Builder. */

        // Register for Keyboard Notifications
        subscribeToNotification(NSNotification.Name.UIKeyboardWillShow.rawValue, selector: Selector(Constant.Selectors.KeyboardWillShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardWillHide.rawValue, selector: Selector(Constant.Selectors.KeyboardWillHide))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidShow.rawValue, selector: Selector(Constant.Selectors.KeyboardDidShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidHide.rawValue, selector: Selector(Constant.Selectors.KeyboardDidHide))
        
        // Initialize Textfield and Error Label arrays with View Textfields and Labels
        self.textFieldsArray = [self.emailTextField]
        self.textFieldErrorLabelsArray = [self.emailErrorLabel]
        
        // Initialize the Validation Engine
        initializeValidator()
        
    }
    
    // MARK: - IBActions
    @IBAction func resetChangePasswordPressed(_ sender: UIButton) {
        
        // Animate textfields Validation
        UIView.animate(withDuration: Constant.AnimationTime.Default, animations: {
            
            // Validate Textfields
            self.validator.validate(self)
            
            // Refresh Layout after animation
            self.view.setNeedsLayout()
        }) 
        
        // Sort action by Button Title
        if sender.titleLabel?.text == Constant.PasswordActionsButtonTitle.Reset {
            
            self.firebaseRef!.resetPassword(forUser: self.emailTextField.text, withCompletionBlock: { error in
                if error != nil {
                    // There was an error processing the request to Reset Password
                    Helper.defaultAlertWithTitle("Server Response Fail",andMessage:"Error Resetting Password", toViewController:self)
                } else {
                    
                    // Alert Controller
                    let alertController = UIAlertController(title: "Password Reset Requested", message: "A Password reset was requested, you will receive an email with instructions shortly", preferredStyle: .alert)
                    
                    // Alert Actions (1)
                    let cancelAction = UIAlertAction(title: "Done", style: .cancel) { (action) in
                        // Password reset sent successfully
                        _ = self.navigationController?.popViewController(animated: true)
                    }
                    
                    // Add Alerts to Alert Controller
                    alertController.addAction(cancelAction)
                    
                    // Present Alert
                    self.present(alertController, animated: true) {
                        print("Alert View for User Name was presented")
                    }
                    

                }
            })
        }
        
    }
    
    // MARK: - Notifications Handling Methods
    fileprivate func subscribeToNotification(_ notification: String, selector: Selector) {
        // Add Notification Observers to View Controller
        NotificationCenter.default.addObserver(self, selector: selector, name: NSNotification.Name(rawValue: notification), object: nil)
    }
    
    fileprivate func unsubscribeFromAllNotifications() {
        // Remove Notification Observers from View Controller
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private Functions
    fileprivate func clearValidationErrors() {
        
        // Set TextField Borders to Black
        for textField in self.textFieldsArray {
            (textField as AnyObject).layer.borderColor = UIColor.black.cgColor
            (textField as AnyObject).layer.borderWidth = Constant.BorderWidthFor.Default
        }
        
        // Hide Error Labels
        for label in self.textFieldErrorLabelsArray {
            (label ).isHidden = true
        }
        
    }
    
    fileprivate func initializeValidator() {
        
        // Establish Style for Error and for Successful Validation
        validator.styleTransformers(success:{ (validationRule) -> Void in
            validationRule.errorLabel?.isHidden = true
            validationRule.errorLabel?.text = Constant.Textfield.EmptyString
            //validationRule.textField.layer.borderWidth = Constant.BorderWidthFor.Success
            
            }, error:{ (validationError) -> Void in
                validationError.errorLabel?.isHidden = false
                validationError.errorLabel?.text = validationError.errorMessage
                //validationError.textField.layer.borderColor = UIColor.redColor().CGColor
                //validationError.textField.layer.borderWidth = Constant.BorderWidthFor.Error
        })
        
        // Register TextFields for Validation
        self.validator.registerField(self.emailTextField, errorLabel: self.emailErrorLabel, rules: [RequiredRule(), EmailRule(message: Constant.Validation.EmailError)])
    }

}

// MARK: - Extension: Keyboard Notification Methods
extension ForgotPasswordViewController {
    
    func keyboardWillShow(_ notification: Notification) {

        // Get Keyboard Info and Size from Notification
        let keyboardInfo : NSDictionary = notification.userInfo! as NSDictionary
        let keyboardSize = (keyboardInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        
        // Get Location and Dimension of TextField and Location and Dimension of current ViewController View
        let textFieldRect : CGRect = self.view.window!.convert(activeField!.bounds, from: activeField)
        let viewRect : CGRect = self.view.window!.convert(self.view.bounds, from: self.view)
        
        // Get the mid-point/mid-line of the Textfield
        let textfieldMidline : CGFloat = textFieldRect.origin.y + Constant.Keyboard.HeightFractioner * textFieldRect.size.height
        
        // Calculate a fraction to get the Animation Distance of the Keyboard
        let numerator : CGFloat = textfieldMidline - viewRect.origin.y - Constant.MoveKeyboard.MINIMUM_SCROLL_FRACTION * viewRect.size.height
        let denominator : CGFloat = (Constant.MoveKeyboard.MAXIMUM_SCROLL_FRACTION - Constant.MoveKeyboard.MINIMUM_SCROLL_FRACTION) * viewRect.size.height
        let heightFraction = (numerator / denominator) > Constant.Keyboard.FullHeight ? Constant.Keyboard.FullHeight : (numerator / denominator)
        animateDistance = floor(keyboardSize!.height * heightFraction)
        
        // Update a new ViewFram with the position for avoiding the Keyboard
        var viewFrame : CGRect = self.view.frame
        viewFrame.origin.y = keyboardOnScreen ? -animateDistance:(viewFrame.origin.y - animateDistance)
        self.view.frame = viewFrame
        
        //  Call Method to perform animation based on Keyboard animation curve and durantion
        animateMoveOfViewFrame(viewFrame, notification: notification)
        
    }
    
    func keyboardWillHide(_ notification: Notification) {
        // Update a new ViewFrame to get View in Original position
        var viewFrame : CGRect = self.view.frame
        viewFrame.origin.y += animateDistance
        
        //  Call Method to perform animation based on Keyboard animation curve and durantion
        animateMoveOfViewFrame(viewFrame, notification: notification)
        
    }
    
    func keyboardDidShow(_ notification: Notification) {
        self.keyboardOnScreen = true
    }
    
    func keyboardDidHide(_ notification: Notification) {
        self.keyboardOnScreen = false
    }
    
    fileprivate func animateMoveOfViewFrame(_ viewFrame: CGRect, notification: Notification) {
        
        // Get Keyboard Info and Size from Notification
        let keyboardInfo : NSDictionary = notification.userInfo! as NSDictionary
        
        // Get animation duration from Keyboard Information taken from notification
        let duration:TimeInterval = (keyboardInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? Constant.Keyboard.CeroTimeInterval
        
        // Get animation curve from Keyboard Information taken from notification
        let animationCurveRawNSN = keyboardInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions().rawValue
        let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
        
        // Use Duration and Animation Curve to animate the Scrolling of the View to new Height
        UIView.animate(withDuration: duration,
            delay: TimeInterval(Constant.Keyboard.CeroTimeInterval),
            options: animationCurve,
            animations: {
                
                // Animate change of ViewFrame
                self.view.frame = viewFrame
                
                // Redraw Layout to ensure each subview is in the correct position based on constraints
                self.view.layoutIfNeeded()

            }, completion: nil)
    }
    
}

// MARK: - Extension: UITextFieldDelegate Methods
extension ForgotPasswordViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        // Assign textfield to Controller Property
        activeField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        // Release Keyboard and clear textfield property
        activeField?.resignFirstResponder()
        activeField = nil
        
        // Flag system for layout refresh due to different animation occuring.
        self.view.layoutIfNeeded()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Release Keyboard
        textField.resignFirstResponder()
        
        // Flag system for layout refresh due to different animation occuring.
        self.view.layoutIfNeeded()

        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String)-> Bool {
        // Ignore any change that doesn't add characters to the text field.
        // These changes are things like character deletions and cuts, as well
        // as moving the insertion point.
        //
        // Still return true to allow the change to take place.
        if string.characters.count == Constant.Textfield.NoCharacters {
            return true
        }
        
        // Check to see if the text field's contents still fit the constraints
        // with the new content added to it.
        // If the contents still fit the constraints, allow the change
        // by returning true; otherwise disallow the change by returning false.
        let currentText = textField.text ?? Constant.Textfield.EmptyString
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        switch textField {
            
            // Disallow characters provided in constant and limit its contents to a maximum of 45 characters.
        case self.emailTextField:
            return prospectiveText.doesNotContainCharactersIn(Constant.CharactersNotAllowedIn.Email) &&
                prospectiveText.characters.count <= Constant.Textfield.MaxEmailSize
            
        default:
            return true
        }
        
    }
}

// MARK: - Extension: ValidationDelegate Methods
extension ForgotPasswordViewController: ValidationDelegate {
    
    func validationSuccessful() {
        self.view.endEditing(true)
        
    }
    func validationFailed(_ errors: [(Validatable, SwiftValidator.ValidationError)]) {
        print("Validation FAILED!")

    }
    
}
