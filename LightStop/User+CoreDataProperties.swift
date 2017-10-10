//
//  User+CoreDataProperties.swift
//  LightStop
//
//  Created by Clara Chen on 2/2/17.
//  Copyright © 2017 GangOfFive. All rights reserved.
//

import Foundation
import CoreData

extension User{
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User");
    }
    
    @NSManaged public var email: String?
    @NSManaged public var firstname: String?
    @NSManaged public var lastname: String?
    @NSManaged public var password: String?
    
}
