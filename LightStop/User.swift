//
//  Users.swift
//  LightStop
//
//  Created by Clara Chen on 12/20/16.
//  Copyright © 2016 GangOfFive. All rights reserved.
//

import Foundation
import CoreData

class User: NSManagedObject {
    
    struct Keys {
        static let Email = "email"
        static let Uid = "uid"
        static let FirstName = "firstName"
        static let LastName = "lastName"
        static let Password = "password"
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    
    /**
     * The two argument Init method. The method will :
     * - insert the new User into a Core Data Managed Object Context
     * - initialize the User properties from a dictionary
     */
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "User", in: context)!
        super.init(entity: entity, insertInto: context)
        
        //Init the properties of the User Object
        email = dictionary[Keys.Email] as? String
        firstname = dictionary[Keys.FirstName] as? String
        lastname = dictionary[Keys.LastName] as? String
        password = dictionary[Keys.Password] as? String
        
    }
}

