//
//  Location+CoreDataProperties.swift
//  LightStop
//
//  Created by Clara Chen on 2/23/17.
//  Copyright © 2017 GangOfFive. All rights reserved.
//

import Foundation
import CoreData

extension Location {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location");
    }
    
    @NSManaged public var locationID: String?
    @NSManaged public var latitude: String?
    @NSManaged public var longitude: String?
}
