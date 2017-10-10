//
//  Location.swift
//  LightStop
//
//  Created by Clara Chen on 2/23/17.
//  Copyright © 2017 GangOfFive. All rights reserved.
//

import Foundation
import CoreData

class Location: NSManagedObject {
    struct Keys {
        static let Lid = "locationID"
        static let Longitude = "longitude"
        static let Latitude = "latitude"
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    /**
     * The two arguemtn Init method. The method will:
     * - insert the new Location into a Core Data Managed Object Context
     * - initialize the Location properties from a dictionary
     */
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "Location", in: context)!
        super.init(entity: entity, insertInto: context)
        
        //Init the properties of the Location Object
        locationID = dictionary[Keys.Lid] as? String
        latitude = dictionary[Keys.Latitude] as? String
        longitude = dictionary[Keys.Longitude] as? String
    }
}
