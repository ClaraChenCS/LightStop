//
//  ChatSelectionTableViewController.swift
//  Vidabase
//
//  Created by Carlos Martinez on 4/26/16.
//  Copyright © 2016 Carlos Martinez. All rights reserved.
//

import UIKit


// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


// MARK: - Implementation
class ChatSelectionTableViewController: UITableViewController {
    // MARK: Properties
    var loggedUser:User?
    var selectedContact:[String:AnyObject] = [:]
    // Hardcoded VID.AI bot (User)
    let monisha:[String:AnyObject] = [
        Contact.Keys.ContactType:"User" as AnyObject,
        Contact.Keys.Email:"monisha.dash@sjsu.edu" as AnyObject,
        Contact.Keys.Image: UIImage.init(named:"monisha")!,
        Contact.Keys.FirstName: "Monisha" as AnyObject,
        Contact.Keys.LastName: "Dash" as AnyObject,
        Contact.Keys.LastComments: "" as AnyObject,
        "uid":"vnRsJgRTS1dqiipWzIbRzDlTwuC3" as AnyObject,
        "chatUrl":"" as AnyObject
    ]
    
    // Harcoded Doctor (User)
    let clara:[String:AnyObject] = [
        Contact.Keys.ContactType:"User" as AnyObject,
        Contact.Keys.Email:"khine.oo@sjsu.edu" as AnyObject,
        Contact.Keys.Image: UIImage.init(named:"clara")!,
        Contact.Keys.FirstName: "Clara" as AnyObject,
        Contact.Keys.LastName: "Chen" as AnyObject,
        Contact.Keys.LastComments: "" as AnyObject,
        "uid":"AlEtGl9NPXZ6DLY9rdEtLyGhiSg2" as AnyObject,
        "chatUrl":"" as AnyObject
        
    ]
    
    // Harcoded Doctor (User)
    let carlos1:[String:AnyObject] = [
        Contact.Keys.ContactType:"User" as AnyObject,
        Contact.Keys.Email:"camg.apple@gmail.com" as AnyObject,
        Contact.Keys.Image: UIImage.init(named:"carlos")!,
        Contact.Keys.FirstName: "Carlos" as AnyObject,
        Contact.Keys.LastName: "Martinez" as AnyObject,
        Contact.Keys.LastComments: "" as AnyObject,
        "uid":"1aed7355-8708-4e5f-9ff5-714c86fe6868" as AnyObject,
        "chatUrl":"" as AnyObject
        
    ]
    
    // Harcoded Doctor (User)
    let carlos2:[String:AnyObject] = [
        Contact.Keys.ContactType:"User" as AnyObject,
        Contact.Keys.Email:"camg.solutions@gmail.com" as AnyObject,
        Contact.Keys.Image: UIImage.init(named:"carlos")!,
        Contact.Keys.FirstName: "Carlos" as AnyObject,
        Contact.Keys.LastName: "Martinez" as AnyObject,
        Contact.Keys.LastComments: "" as AnyObject,
        "uid":"kY1ksFu1Y1T7MNx6dUmvLVySFBP2" as AnyObject,
        "chatUrl":"" as AnyObject
        
    ]
    
    // Harcoded Doctor (User)
    let ali:[String:AnyObject] = [
        Contact.Keys.ContactType:"User" as AnyObject,
        Contact.Keys.Email:"ali.parandian@sjsu.edu" as AnyObject,
        Contact.Keys.Image: UIImage.init(named:"ali")!,
        Contact.Keys.FirstName: "Ali" as AnyObject,
        Contact.Keys.LastName: "Parandian" as AnyObject,
        Contact.Keys.LastComments: "" as AnyObject,
        "uid":"w6Fu8zHGhiNqxhaD7YLDgchjtqp1" as AnyObject,
        "chatUrl":"" as AnyObject
        
    ]
    
    // Harcoded Doctor (User)
    let abhay:[String:AnyObject] = [
        Contact.Keys.ContactType:"User" as AnyObject,
        Contact.Keys.Email:"abhayshreeranga.rao@sjsu.edu" as AnyObject,
        Contact.Keys.Image: UIImage.init(named:"abhay")!,
        Contact.Keys.FirstName: "Abhay" as AnyObject,
        Contact.Keys.LastName: "Rao" as AnyObject,
        Contact.Keys.LastComments: "" as AnyObject,
        "uid":"hRl7BmVkimPnAo6lTINp40odC8p1" as AnyObject,
        "chatUrl":"" as AnyObject
        
    ]

    var contacts:[NSDictionary] = []
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Append Temp Users
        self.contacts.append(monisha as NSDictionary)
        self.contacts.append(carlos1 as NSDictionary)
        self.contacts.append(carlos2 as NSDictionary)
        self.contacts.append(ali as NSDictionary)
        self.contacts.append(clara as NSDictionary)
        self.contacts.append(abhay as NSDictionary)

    
        
        
        var indexToRemove:Int?
        for user in contacts {
            let email = user["email"] as! String
            if email == self.loggedUser?.email {
                indexToRemove = contacts.index(of: user)
            }
        }
        
        if let indexToRemove = indexToRemove {
            contacts.remove(at: indexToRemove)
        }
        
        // display an Edit button in the navigation bar.
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Hide Status Bar
    override public var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:ContactsTableViewCell = tableView.dequeueReusableCell(withIdentifier: "contactsCell", for: indexPath) as! ContactsTableViewCell

        let contact = contacts[indexPath.row]
        cell.nameLabel.text = contact[Contact.Keys.FirstName] as? String
        cell.contactImageView.image = contact[Contact.Keys.Image] as? UIImage
        cell.lastCommentLabel.text = contact[Contact.Keys.Email] as? String

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedContact = self.contacts[indexPath.row] as! [String : AnyObject]
        
        if let test = self.selectedContact["uid"] as? String {
            // Create a URL using both user UID and add to Firebase
            self.selectedContact["chatUrl"] = prepareUrlWithUserUid(test) as AnyObject?
            
            // Perform Segue
            performSegue(withIdentifier: "ContactToChatSegue", sender: self)
        }
 
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    // MARK: - Custom Methods
    // Method to creat an URL out of user UIDs always sorted <
    fileprivate func prepareUrlWithUserUid(_ userUid:  (String)) -> String {
        
        var userIds = [self.loggedUser?.uid, userUid]
        userIds.sort(){$0 < $1}
        
        var uidUrl = ""
        for uid in userIds {
            uidUrl = uidUrl + uid!
        }
        
        return uidUrl
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //
        
        
        if segue.identifier == "ContactToChatSegue" {
            guard let chatbotViewController = segue.destination as? ChatbotViewController else {return}
            //guard let chatbotViewController = navigationVC.viewControllers.last as? ChatbotViewController else {return}
            chatbotViewController.contactUser = self.selectedContact
            chatbotViewController.loggedUser = self.loggedUser
            chatbotViewController.senderId = self.loggedUser?.uid
            chatbotViewController.senderDisplayName = self.loggedUser?.email
        }
    }

}
