//
//  AuthenticationViewController.swift
//  Kamptive
//
//  Created by Carlos Martinez on 3/8/16.
//  Copyright © 2016 Carlos Martinez. All rights reserved.
//

import UIKit
import CoreData         // iOS Core Data Framework
import Alamofire        // Linked Framework - Requires: iOS 8.0+, Xcode 7.2+
import SwiftValidator   // Linked Framework - Requires: iOS 8.1+
import Firebase         // Backend service SDK library

// MARK: - Class Implementation
class AuthenticationViewController: UIViewController, NSFetchedResultsControllerDelegate,UIPickerViewDelegate, UIPickerViewDataSource{
    
    // MARK: Properties
    var animateDistance = CGFloat()                     // Animation Distance for Keyboard
    var keyboardOnScreen = false                        // Flag for Keyboard: On Screen or Not
    var activeField: UITextField?                       // Hold active textfield reference
    var validator = Validator()                         // Textfield Validator Object
    var textFieldsArray = [UITextField]()                            // Array to hold reference to all textfields in view
    var textFieldErrorLabelsArray = [UILabel]()                  // Array to hold references to all textfield error labels
    var managedObjectContext:NSManagedObjectContext?    // Hold reference to the ManagedObjectContext (Core Data)
    var loggedUser:User?                                // Hold reference to the current logged User
    var webPageUrl:URL?                               // Hold reference to web page for Privacy Policy or Terms or Use
    let firebaseRef = Firebase(url: "https://vidabase.firebaseio.com")
    var userSelection:AuthenticationOptions?            // Hold User Selection (Signup or Login) from Intro Screen
    
    // MARK: IBOutlets
    @IBOutlet weak var facebookStackView: UIStackView!          //
    @IBOutlet weak var facebookButton: UIButton!                //
    @IBOutlet weak var actionMessageLabel: UILabel!             //
    @IBOutlet weak var emailTextField: UITextField!             //
    @IBOutlet weak var passwordTextField: UITextField!          //
    @IBOutlet weak var confirmPasswordTextField: UITextField!   //
    @IBOutlet weak var agreementStackView: UIStackView!         //  References to elements of the View
    @IBOutlet weak var loginSignupButton: UIButton!             //
    @IBOutlet weak var forgotPasswordButton: UIButton!          //
    @IBOutlet weak var toggleShowLoginSignupButton: UIButton!   //
    @IBOutlet weak var socialLoginDivisionLineView: UIView!     //
    @IBOutlet weak var emailErrorLabel: UILabel!                //
    @IBOutlet weak var passwordErrorLabel: UILabel!             //
    @IBOutlet weak var confirmPasswordErrorLabel: UILabel!      //
    //picker view
    @IBOutlet weak var gradYearTextField: UITextField!
    let pickerView = UIPickerView()
    var pickYear = ["Junior","Sophomore","Freshman","Senior"]
    var gradYear:String = ""
    
    // Lazy property for the FetchedResultController - Initialized on request
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        
        // Constant to hold entity to Fetch from local Core Data Database
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Constant.Entity.User)
        
        // Set Sort Descriptor - Sort results by 'email address' ascending
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Constant.Attribute.Email, ascending: true)]
        
        // Constant to hold a fetch result controller; initialized with "Entity name" and "sort descriptor" and "shared Context"
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    // MARK: - Core Data Convenience Singlelton
    var sharedContext: NSManagedObjectContext {
        
        // This singleton pack the Core Data Stack in a convenient method; this returns the managed object context
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //*********** Remove on production *************
        //self.performSegueWithIdentifier("AuthenticationViewControllerToTabBarControllerSegue", sender: nil)

        /* Note: "Agreement Stack View" and "Confirm Password Text Field" are hidden at     *
         *        runtime using the "User Defined Runtime Attributes" in Interface Builder. */
        
        // Register for Keyboard Notifications
        subscribeToNotification(NSNotification.Name.UIKeyboardWillShow.rawValue, selector: Selector(Constant.Selectors.KeyboardWillShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardWillHide.rawValue, selector: Selector(Constant.Selectors.KeyboardWillHide))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidShow.rawValue, selector: Selector(Constant.Selectors.KeyboardDidShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidHide.rawValue, selector: Selector(Constant.Selectors.KeyboardDidHide))
        
        // Initialize Textfield and Error Label arrays with View Textfields and Error Labels
        self.textFieldsArray = [self.emailTextField, self.passwordTextField, self.confirmPasswordTextField]
        self.textFieldErrorLabelsArray = [self.emailErrorLabel, self.passwordErrorLabel, self.confirmPasswordErrorLabel]
        
        // Initialize the Validation Engine
        initializeValidator()
        
        // Set the fetchedResultsController.delegate = self
        fetchedResultsController.delegate = self
        
        // Perform initial fetch for Users
        do {
            try fetchedResultsController.performFetch()
        } catch {
            // Notify user of error performing fetch
            Helper.defaultAlertWithTitle("Fetch Error", andMessage:"Error Fetching from Core Data", toViewController:self)
        }
        //picker View
        //let pickerView = UIPickerView()
        pickerView.delegate = self
        gradYearTextField.inputView = pickerView
        self.gradYearTextField.isHidden = true
        gradYear = gradYearTextField.text!
        
        // Setup delegates for GOOGLE Sign In
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        // Attempt to sign in silently, this will succeed if
        // the user has recently been authenticated
        GIDSignIn.sharedInstance().signInSilently()
        
        // Execute User Selection in transition screen
        if userSelection == AuthenticationOptions.Login {
            prepareForAuthenticationSequence(AuthenticationOptions.Login, animated: true)
        } else {
            prepareForAuthenticationSequence(AuthenticationOptions.Signup, animated: true)
        }
    }
    
    // MARK: - Hide Status Bar
    override public var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    //picker view grad year
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickYear.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickYear[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        gradYearTextField.text = pickYear[row]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove Notification Subscription before exiting view
        unsubscribeFromAllNotifications()
    }
    
    // MARK: - IBActions
    
    @IBAction func authenticateWithGoogle(_ sender: UIButton) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func loginSignupPressed(_ sender: UIButton) {
        
        // Start Activity indicator spinner
        Helper.addActivityIndicatorToView(self.view)

        // Animate textfields Validation
        UIView.animate(withDuration: Constant.AnimationTime.Default, animations: {
            
            // Validate Textfields
            self.validator.validate(self)
            
            // Refresh Layout after animation
            self.view.setNeedsLayout()
        }) 
        
        // Sort action by Button Title
        if sender.titleLabel?.text == Constant.AuthenticationButtonTitle.Signup {
            
            self.firebaseRef?.createUser(self.emailTextField.text!, password: self.passwordTextField.text!, withValueCompletionBlock: { error, result in
                if error != nil {
                    // Show alert due to an error creating the account in Firebase - Using Helper Class Methods
                    Helper.defaultAlertWithTitle("Error Creating Account", andMessage:"An error occurred creating the new account. Please Try Again.", toViewController:self)
                } else {
                    let uid = result?["uid"] as? String
                    print("Successfully created user account with uid: \(uid)")
                    
                    // Search Core data database for user; if not available it will create a new user with email and uid
                    self.searchUserOrCreate(self.emailTextField.text!, uid: uid!)
                }
                
                // Remove Activity Indicator
                Helper.removeActivityIndicatoryFromView(self.view)
            })
            
        } else {
            
            self.firebaseRef?.authUser(self.emailTextField.text!, password: self.passwordTextField.text!, withCompletionBlock: { error, authData in
                if error != nil {
                    // Show alert due to an error creating the account in Firebase - Using Helper Class Methods
                    Helper.defaultAlertWithTitle("Error Loggin into Account", andMessage:"An error occurred while loggin into the account. Please Try Again.", toViewController:self)
                } else {
                    
                    // Search Core data database for user; if not available it will create a new user with email and uid
                    self.searchUserOrCreate(self.emailTextField.text!, uid: (authData?.uid)!)
                }
                
                // Remove Activity Indicator
                Helper.removeActivityIndicatoryFromView(self.view)
            })

        }
    }
    
    @IBAction func toggleShowLoginSignupPressed(_ sender: UIButton) {
        
        // Clear Validation Error before change Authentication Mode
        clearValidationErrors()
        
        if sender.titleLabel?.text == Constant.AuthenticationToggle.Login {
            
            // Prepare Controller for Sign Up authentication sequence
            prepareForAuthenticationSequence(AuthenticationOptions.Login, animated: true)
            
        } else {
            
            // Prepare Controller for Login authentication sequence
            prepareForAuthenticationSequence(AuthenticationOptions.Signup, animated: true)
            
        }
        
    }
    
    @IBAction func agreementPolicyPressed(_ sender: UIButton) {

        if sender.tag == Constant.DocumentTag.UserAgreement {
            // Set url for User Agreement / Terms
            webPageUrl = URL(string: Constant.API.Production.UserAgreementURL)
        }
        if sender.tag == Constant.DocumentTag.PrivacyPolicy {
            
            // Set url for Privacy Policy
            webPageUrl = URL(string: Constant.API.Production.UserAgreementURL)
        }
        
        // Perform Segue to WebViewController to show Terms or Privacy page
        performSegue(withIdentifier: Constant.Segue.AgreementPrivacy, sender: self)
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
    
    // MARK: - Custom Methods
    fileprivate func prepareForAuthenticationSequence(_ authentication: AuthenticationOptions, animated:Bool) {
        
        // Check if sequence must be animated and establish the animation duration
        let animationDuration = animated ? Constant.AnimationTime.Default:Constant.AnimationTime.NoAmination
        
        // Switch between authentication options defined in ENUM AuthenticationOptions
        switch authentication {
        case .Login:
            
            // Animate hidding or showing views
            UIView.animate(withDuration: animationDuration, animations: {
                
                // Sequence of steps needed to setup the Login Screen
                self.confirmPasswordTextField.isHidden = true
                self.agreementStackView.isHidden = true
                self.forgotPasswordButton.isHidden = false
                self.facebookStackView.isHidden = false
                self.facebookButton.isHidden = false
                self.gradYearTextField.isHidden = true
                self.socialLoginDivisionLineView.isHidden = false
                self.loginSignupButton.setTitle(Constant.AuthenticationButtonTitle.Login, for: UIControlState())
                self.toggleShowLoginSignupButton.setTitle(Constant.AuthenticationToggle.Signup, for: UIControlState())
                
                // Remove confirmPassword textfield validation, since field is hidden
                self.validator.unregisterField(self.confirmPasswordTextField)
                self.validator.unregisterField(self.gradYearTextField)

                // Redraw Layout to ensure each subview is in the correct position based on constraints
                self.view.layoutIfNeeded()
            }) 
            
        case .Signup:
            
            // Animate hidding or showing views
            UIView.animate(withDuration: animationDuration, animations: {
                
                // Sequence of steps needed to setup the SignUp Screen
                self.confirmPasswordTextField.isHidden = false
                self.agreementStackView.isHidden = false
                self.forgotPasswordButton.isHidden = true
                self.facebookStackView.isHidden = true
                self.facebookButton.isHidden = true
                self.gradYearTextField.isHidden = false
                self.socialLoginDivisionLineView.isHidden = true
                self.loginSignupButton.setTitle(Constant.AuthenticationButtonTitle.Signup, for: UIControlState())
                self.toggleShowLoginSignupButton.setTitle(Constant.AuthenticationToggle.Login, for: UIControlState())
                
                // Register for confirmPassword textfield validation
                self.validator.registerField(self.confirmPasswordTextField, errorLabel: self.confirmPasswordErrorLabel, rules: [RequiredRule(), ConfirmationRule(confirmField: self.passwordTextField)])
                
                // Redraw Layout to ensure each subview is in the correct position based on constraints
                self.view.layoutIfNeeded()
            }) 
        }
    }
    
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
            validationRule.errorLabel?.text = ""
            //validationRule.textField.layer.borderWidth = Constant.BorderWidthFor.Success
            
            }, error:{ (validationError) -> Void in
                validationError.errorLabel?.isHidden = false
                validationError.errorLabel?.text = validationError.errorMessage
                //validationError.textField.layer.borderColor = UIColor.redColor().CGColor
                //validationError.textField.layer.borderWidth = Constant.BorderWidthFor.Error

        })
        
        // Register TextFields for Validation
        self.validator.registerField(self.emailTextField, errorLabel: self.emailErrorLabel, rules: [RequiredRule(), EmailRule(message: Constant.Validation.EmailError)])
        self.validator.registerField(self.passwordTextField, errorLabel: self.passwordErrorLabel, rules: [RequiredRule(), PasswordRule()])
    }
    
    fileprivate func createNewUserWithEmailAndUid(_ email:String, uid:String) {
        
        // No User in Local Database - Construct Dictionary for New User
        let newUserDictionary: [String : String] = [
            User.Keys.Uid :uid,
            User.Keys.Email : email,
            User.Keys.GraduationYear : gradYear
        ]
        
        // We Create a new user in local database and assign to property.
        // This is done to be able to pass the user to other View Controllers
        self.loggedUser = User(dictionary: newUserDictionary as [String : AnyObject], context: self.sharedContext)
        
        // Save added or modified data to MySQL database
        CoreDataStackManager.sharedInstance().saveContext()
        
    }
    
    fileprivate func searchUserOrCreate (_ email:String, uid:String){
        
        // Check if user Exist is in Local Database. Query local Database with fetch request and predicate
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Constant.Entity.User)
        fetchRequest.predicate = NSPredicate(format: Constant.Predicate.Email, email)
        
        do {    // Try-Catch the fetch request
            let fetchedUser = try self.sharedContext.fetch(fetchRequest) as! [User]
            
            // We should have no more that one user with the email address, or alternatively No user
            if fetchedUser.count == 1 {
                
                // Assign the found user to the ViewController property.
                // This is done to be able to pass the user to other View Controllers
                self.loggedUser = fetchedUser.last
                
                // Add the new token received from the server.
                self.loggedUser?.uid = uid
                
                // Save added or modified data to MySQL database
                CoreDataStackManager.sharedInstance().saveContext()
                
            } else if fetchedUser.count < 1 {
                
                // Create and Save New User in Local Database
                self.createNewUserWithEmailAndUid(email, uid: uid)
                
            } else {
                // Suspicious response from database - Should not be more that one user with same email.
                // Could mean compromissed database or internal error.
                print("Error: Data Error, more that one user with the same email")
                
                // Show alert due to Facebook error - Using Helper Class Methods
                Helper.defaultAlertWithTitle("Error Retrieving User", andMessage:"More than one user with the same Email", toViewController:self)
                
                return
            }
            
            // Present Tab Bar Controller (Main View) since user was Authenticated successfully
            self.performSegue(withIdentifier: "AuthenticationViewControllerToTabBarControllerSegue", sender: nil)
            
        } catch {
            // Show alert due to Facebook error - Using Helper Class Methods
            Helper.defaultAlertWithTitle("Fatal Core Data Error", andMessage:"Error Retrieving User. App execution will end!", toViewController:self)
            
            fatalError("Failed to fetch user: \(error)")
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Constant.Segue.AgreementPrivacy {
            
            guard let webViewController = segue.destination as? WebViewController else { return }
            webViewController.url = webPageUrl
        }
        
        if segue.identifier == "AuthenticationViewControllerToTabBarControllerSegue" {
            
            guard let tabbarcontroller = segue.destination as? UITabBarController else { print("Error Unwrapping destination VC"); return }
            //guard let timelineViewController = tabbarcontroller.viewControllers![0] as? TimelineViewController else { print("Error Unwrapping Timeline VC"); return }
//            guard let lifestageViewController = tabbarcontroller.viewControllers![1] as? LifestageViewController else { print("Error Unwrapping Lifestage VC"); return }
            guard let navChatbotViewController = tabbarcontroller.viewControllers![0] as? UINavigationController else { print("Error Unwrapping UINav VC"); return }
            guard let profileViewController = tabbarcontroller.viewControllers![2] as?
                ProfileViewController else { print ("Error Unwrapping Profile VC"); return }
            guard let chatSelectionTableViewController = navChatbotViewController.topViewController as? ChatSelectionTableViewController else { print("Error Unwrapping Chatbot VC"); return }
            
            //timelineViewController.loggedUser = self.loggedUser
            //lifestageViewController.loggedUser = self.loggedUser
            profileViewController.loggedUser = self.loggedUser
            // Set Up Chat Bot
            chatSelectionTableViewController.loggedUser = self.loggedUser

        }
        
        if segue.identifier == "AuthenticationViewControllerToForgotPasswordViewControllerSegue" {
            guard let forgotPasswordViewController = segue.destination as? ForgotPasswordViewController else { print("Error Unwrapping ForgotPass VC"); return }
            forgotPasswordViewController.firebaseRef = self.firebaseRef
        }
        
    }
}

// MARK: - Extension: Keyboard Notification Methods
extension AuthenticationViewController {
    
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
extension AuthenticationViewController: UITextFieldDelegate {
    
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
            
        // Limit its contents to a maximum of 30 characters.
        case self.passwordTextField:
            return prospectiveText.characters.count <= Constant.Textfield.MaxPasswordSize
            
        case self.confirmPasswordTextField:
            return prospectiveText.characters.count <= Constant.Textfield.MaxPasswordSize

        default:
            return true
        }
        
    }
}


// MARK: - Extension: ValidationDelegate Methods
extension AuthenticationViewController: ValidationDelegate {
    /**
     This method will be called on delegate object when validation fails.
     
     - returns: No return value.
     */
    public func validationFailed(_ errors: [(Validatable, ValidationError)]) {
        print("Validation FAILED!")

    }

    
    func validationSuccessful() {
        self.view.endEditing(true)
        
    }

}

extension AuthenticationViewController: GIDSignInDelegate, GIDSignInUIDelegate {
    // Implement the required GIDSignInDelegate methods
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!){

        if (error == nil) {
            // Auth with Firebase
            firebaseRef?.auth(withOAuthProvider: "google", token: user.authentication.accessToken, withCompletionBlock: { (error, authData) in
                
                if(error != nil){
                    print("\(error?.localizedDescription)")
                } else {
                    print("Data: \(authData)")
                    print("Data: \(authData?.uid)")
                    print("Data: \(authData?.providerData["email"])")
                    self.searchUserOrCreate(authData?.providerData["email"] as! String, uid: (authData?.uid)!)
                    // User is logged in!
                    // Present Tab Bar Controller (Main View) since user was Authenticated successfully
                    self.performSegue(withIdentifier: "AuthenticationViewControllerToTabBarControllerSegue", sender: nil)
                }
                


            })
        } else {
            // Don't assert this error it is commonly returned as nil
            print("\(error.localizedDescription)")
        }

    }

    // Implement the required GIDSignInDelegate methods
    // Unauth when disconnected from Google
    public func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!){
        firebaseRef?.unauth();
    }
    
    func signOut() {
        GIDSignIn.sharedInstance().signOut()
        firebaseRef?.unauth()
    }
}
