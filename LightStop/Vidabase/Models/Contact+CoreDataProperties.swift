//
//  Contact+CoreDataProperties.swift
//  Vidabase
//
//  Created by Carlos Martinez on 4/26/16.
//  Copyright © 2016 Carlos Martinez. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Contact {

    @NSManaged var contactType: String?
    @NSManaged var email: String?
    @NSManaged var firstName: String?
    @NSManaged var image: Data?
    @NSManaged var lastComments: NSObject?
    @NSManaged var lastName: String?

}
