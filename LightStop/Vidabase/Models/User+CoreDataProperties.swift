//
//  User+CoreDataProperties.swift
//  uHype
//
//  Created by Carlos Martinez on 12/6/16.
//  Copyright © 2016 Carlos Martinez. All rights reserved.
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User");
    }

    @NSManaged public var authProvider: String?
    @NSManaged public var email: String?
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var uid: String?
    @NSManaged public var graduationYear: String?

}
