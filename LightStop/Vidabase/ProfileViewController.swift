//
//  ProfileViewController.swift
//  uHype
//
//  Created by Clara Chen on 12/8/16.
//  Copyright © 2016 Carlos Martinez. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import CoreData

class ProfileViewController : UIViewController {
    
    //MARK: properties
    var ref: Firebase!
    var loggedUser:User?
    var profileUser:User?
    var managedObjectContext: NSManagedObjectContext? // Hold reference to the ManagedObjectContext(Core Data)
    var profileFirstName: String!
    var profileLastName: String!
    var profileEmail: String!
    var profileGradYear: String!
    
    
    // Lazy property for the FetchedResultController - Initialized on request
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        
        // Constant to hold entity to Fetch from local Core Data Database
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Constant.Entity.User)
        
        // Set Sort Descriptor - Sort results by 'email address' ascending
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Constant.Attribute.Email, ascending: true)]
        
        // Constant to hold a fetch result controller; initialized with "Entity name" and "sort descriptor" and "shared Context"
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext,sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
        
    }()

    //MARK: - Core Data Convenience Singleton
    var sharedContext: NSManagedObjectContext {
        
        //This singleton pack the Core Data Stack in a convenient method; this returns the managed object context
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    
    @IBOutlet weak var uid: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var loggedUserFirstName: UILabel!
        
    @IBOutlet weak var loggedUserLastName: UILabel!
    @IBOutlet weak var loggedUserGradYear: UILabel!
    
    @IBOutlet weak var loggedEmail: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Firebase(url: "https://vidabase.firebaseio.com")
        
        print(loggedUser?.email)
        print(loggedUser?.uid)
        showProfile()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func showProfile(){
    loggedEmail.text = loggedUser?.email
    uid.text = loggedUser?.uid
        
        if(loggedUser?.firstName==nil){
    
            var name = (loggedUser?.email)?.characters.split{$0 == "@"}.map(String.init)
            
            loggedUserFirstName.text = name?[0]
        } else{
            var username = loggedUser?.firstName
                username?.append((loggedUser?.lastName)!)
            loggedUserFirstName.text = username
        }
        
        if(loggedUser?.graduationYear==""){
            loggedUserGradYear.text = "Unspecified"
        } else {
            loggedUserGradYear.text = loggedUser?.graduationYear
        }

//        if(loggedUser?.image == nil){
            profileImage.image = UIImage.init(named:"noprofileimage")
//        }else{
//            profileImage.image = UIImage.init(named:"Robert")
//        }
        
    }

    @IBAction func logout(_ sender: UIButton) {
        performSegue(withIdentifier: "logoutToMainView", sender: self)
    }

    
    @IBAction func editProfile(_ sender: UIButton) {
        performSegue(withIdentifier: "editProfile", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "logoutToMainView"{
            guard let authenticationViewController = segue.destination as? AuthenticationViewController else {return}
            
        }
// Implementation in Progress
//        else if segue.identifier == "editProfile" {
//            guard let editProfileViewController = segue.destination as?
//                EditProfileViewController else {return}
//        }
    }
}
