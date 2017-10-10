//
//  Contact.swift
//  Vidabase
//
//  Created by Carlos Martinez on 4/26/16.
//  Copyright © 2016 Carlos Martinez. All rights reserved.
//

import Foundation
import CoreData


class Contact: NSManagedObject {
    
    struct Keys {
        static let ContactType = "contactType"
        static let Email = "email"
        static let Image = "image"
        static let FirstName = "firstName"
        static let LastName = "lastName"
        static let LastComments = "lastComments"
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    /**
     * The Two argument Init method. The method will:
     *  - insert the new User into a Core Data Managed Object Context
     *  - initialze the User properties from a dictionary
     */
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entity(forEntityName: "Contact", in: context)!
        super.init(entity: entity,insertInto: context)
        
        // Init the properties of the User Object
        email = dictionary[Keys.Email] as? String
        firstName = dictionary[Keys.FirstName] as? String
        lastName = dictionary[Keys.LastName] as? String
        contactType = dictionary[Keys.ContactType] as? String
        image = dictionary[Keys.Image] as? Data
        lastComments = NSKeyedArchiver.archivedData(withRootObject: dictionary[Keys.LastComments] as! Data) as NSObject?
    }
}
