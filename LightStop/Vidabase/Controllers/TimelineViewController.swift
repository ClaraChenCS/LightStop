//
//  TimelineViewController.swift
//  Vidabase
//
//  Created by Carlos Martinez on 4/8/16.
//  Copyright © 2016 Carlos Martinez. All rights reserved.
//
import UIKit
import Firebase

class TimelineViewController: UIViewController {
    // MARK: Properties
    var ref: Firebase!
    var loggedUser:User?
 
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ref = Firebase(url: "https://vidabase.firebaseio.com")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func loginAnnonymousUser() {
        ref.authAnonymously { (error, authData) in
            if error != nil { print(error.debugDescription); return }
            print(self.ref.authData.uid)
            
            let navigationViewController = self.tabBarController?.childViewControllers.last as! UINavigationController
            let chatVc = navigationViewController.childViewControllers.last as! ChatbotViewController
            
            chatVc.senderId = self.ref.authData.uid
            chatVc.senderDisplayName = "Annonymous"
        }
    }
    
   
    /*
    // MARK: - Navigation

     
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
