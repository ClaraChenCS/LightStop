//
//  User.swift
//  Vidabase
//
//  Created by Carlos Martinez on 4/20/16.
//  Copyright © 2016 Carlos Martinez. All rights reserved.
//

import Foundation
import CoreData


class User: NSManagedObject {
    
    struct Keys {
        static let Email = "email"
        static let AuthProvider = "authProvider"
        static let Uid = "uid"
        static let FirstName = "firstName"
        static let LastName = "lastName"
        static let GraduationYear = "graduationYear"

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
        
        let entity =  NSEntityDescription.entity(forEntityName: "User", in: context)!
        super.init(entity: entity,insertInto: context)
        
        // Init the properties of the User Object
        email = dictionary[Keys.Email] as? String
        authProvider = dictionary[Keys.AuthProvider] as? String
        uid = dictionary[Keys.Uid] as? String
        firstName = dictionary[Keys.FirstName] as? String
        lastName = dictionary[Keys.LastName] as? String
        graduationYear = dictionary[Keys.GraduationYear] as? String
      

    }
}
