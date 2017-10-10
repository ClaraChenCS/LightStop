//
//  Helper.swift
//  Kamptive
//
//  Created by Carlos Martinez on 4/6/16.
//  Copyright © 2016 Carlos Martinez. All rights reserved.
//

import UIKit

class Helper: NSObject {
    
    /**
     This Helper Method to convert a Full Name String to a String with First Name and Last Name toghether
     - Parameter fullName: 'String', Full name; First Name and Last Name
     - Returns: 'String', a string with the two initials from first name and last name
     - remark: This method splits string using solution from stackoverflow:
        http://stackoverflow.com/questions/25678373/swift-split-a-string-into-an-array
     */
    class func getInitialsFromFullName(_ fullName:String) -> String {
        
        // Initialize variable
        var letterString:String = ""
        
        // Split Full Name in First Name and Last Name
        let fullNameArr = fullName.characters.split{$0 == " "}.map(String.init)
        
        // Get First Letter of each array element
        for string in fullNameArr {
            letterString.append(string.characters.first!)
        }
        
        return letterString
    }
    
    // MARK: - Constants
    static let kDefaultButtonTitle = "OK"
    
    /**
     This Helper Method creates an AlertViewController with minimun controls (only "OK") to dismiss controller.
     - Parameter title: 'String', provides the title for the AlertViewController.
     - Parameter andMessage: 'String', provides the alert message to display to the user.
     - Parameter toViewController: 'UIViewController', viewcontroller to add the AlertViewController to.
     - Returns: void
     - remark: This method presents a very simple AlertViewController to present a message to the user.
     */
    class func defaultAlertWithTitle(_ title:String, andMessage message:String, toViewController viewController:UIViewController){
        
        // Constant to hold referene to Alert Controller
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Define a Default action when pressing the OK button
        let defaultAction = UIAlertAction(title: kDefaultButtonTitle, style: .default) { (action) in
            // Add action on OK
        }
        
        // Add action to Alert controller
        alertController.addAction(defaultAction)
        
        // Show Alert on View Controller
        viewController.present(alertController, animated: true) {
            // Add action on alert presentation.
        }

    }
    
    // MARK: - Constants
    static let kDefaultAlpha = 1.0
    
    /**
     This Helper Method to convert a Hexadecimal Value to an UIColor
     - Parameter rgbValue: 'UInt32', hexadecimal value to conver to UIColor. Format: '0xffffff'
     - Parameter alpha: 'Double', decimal value for Alpha channel. Range: 0.0 - 1.0
     - Returns: 'UIColor', object defining color equivalent to hexadecimal value.
     */
    class func UIColorFromHex(_ rgbValue:UInt32, alpha:Double=kDefaultAlpha)->UIColor {
        
        // Convert Hexadecimal value to RGB
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        
        // Return UIColor from RGB
        return UIColor(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
    }
    
    // MARK: - Constants
    static let kContainerHexColor:UInt32 = 0xffffff // White
    static let kContainerAlpha = 0.3
    static let kContainerTag = 900001
    
    static let kLoadingViewHexColor:UInt32 = 0x444444 // Grey
    static let kLoadingViewAlpha = 0.7
    static let kLoadingViewRadius:CGFloat = 10
    
    /**
     This Helper Method to add an Activity Indicator (AI) to a provided View.  The AI consist of an Spinner and a square background.
     - Parameter uiView: 'UIView', view where to add the spinner (AI)
     - Returns: void
     - remark: Thid method uses tag number '900001' to identify the spinner (AI) container.  Verify no other view uses this tag number to avoid
            conflicts.
     */
    class func addActivityIndicatorToView(_ uiView: UIView) {
        // Create new UIView (Container)
        let container: UIView = UIView()
        
        // Setup with passed view frame and set center and Color
        container.frame = uiView.frame
        container.center = uiView.center
        container.backgroundColor = Helper.UIColorFromHex(kContainerHexColor, alpha: kContainerAlpha)
        
        // Set View Tag for eventual removal
        container.tag = kContainerTag
        
        // Create a new UIView (Spinner View)
        let loadingView: UIView = UIView()
        
        // Set frame (80x80 square), and set on middle of passed view
        loadingView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        loadingView.center = uiView.center
        
        // Configure apperance (Color and corner radius)
        loadingView.backgroundColor = Helper.UIColorFromHex(kLoadingViewHexColor, alpha: kLoadingViewAlpha)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = kLoadingViewRadius
        
        // Create Spinner
        let spinner: UIActivityIndicatorView = UIActivityIndicatorView()
        
        // Set Spinner frame (half size of view)
        spinner.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0);
        
        // Configure Spinner Stule and center of spinner
        spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        spinner.center = CGPoint(x: loadingView.frame.size.width / 2,y: loadingView.frame.size.height / 2);
        
        // Add view as Subview of other views
        loadingView.addSubview(spinner)
        container.addSubview(loadingView)
        uiView.addSubview(container)
        
        // Start Spinner Animation
        spinner.startAnimating()
    }
    
    /**
     This Helper Method removes a previously added Activity Indicator (AI) from provided View, using
        method addActivityIndicatorToView(uiView: UIView).
     - Parameter uiView: 'UIView', view from where to remove the spinner (AI)
     - Returns: void
     - remark: Thid method uses tag number '900001' to identify the spinner (AI) container.  Verify no other view uses this tag number to avoid
        conflicts.
     */
    class func removeActivityIndicatoryFromView(_ uiView: UIView) {
        
        for subview in uiView.subviews {
            if (subview.tag == kContainerTag) {
                subview.removeFromSuperview()
            }
        }
    }
    
    /**
     This Helper Method creates an AlertViewController for Errors: Unwrapping and Guard Errors.
     - Parameter toViewController: 'UIViewController', viewcontroller to add the AlertViewController to.
     - Returns: void
     - remark: This method presents a very simple AlertViewController to present a message to the user.
     */
    class func unwrapErrorAlert(toViewController viewController:UIViewController){
        
        // Constant to hold referene to Alert Controller
        let alertController = UIAlertController(title: "An Error Ocurred", message: "Please, Try again later", preferredStyle: .alert)
        
        // Define a Default action when pressing the OK button
        let defaultAction = UIAlertAction(title: kDefaultButtonTitle, style: .default) { (action) in
            // Add action on OK
        }
        
        // Add action to Alert controller
        alertController.addAction(defaultAction)
        
        // Show Alert on View Controller
        viewController.present(alertController, animated: true) {
            // Add action on alert presentation.
        }
        
    }


}
