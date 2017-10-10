//
//  CoreDataStackManager.swift
//  Kamptive
//
//  Created by Carlos Martinez on 3/16/16.
//  Copyright © 2016 Carlos Martinez. All rights reserved.
//

import Foundation
import CoreData

/**
* The CoreDataStackManager is a Singleton Class that contains the whole CoreData
* Stack and components.  It also include mayor functions for saving data.
*/

private let SQLITE_FILE_NAME = "vidabase.sqlite"
private let databaseResourceName = "vidabase"
class CoreDataStackManager {

    // MARK: - Shared Instance
    
    /**
    *  This class variable provides an easy way to get access
    *  to a shared instance of the CoreDataStackManager class.
    */
    class func sharedInstance() -> CoreDataStackManager {
        struct Static {
            static let instance = CoreDataStackManager()
        }
        
        return Static.instance
    }
    
    // MARK: - The Core Data stack.
    lazy var applicationDocumentsDirectory: URL = {
        
        // Instantiating the applicationDocumentsDirectory property
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        
        // Instantiating the managedObjectModel property for the application
        let modelURL = Bundle.main.url(forResource: databaseResourceName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    // The Persistent Store Coordinator
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        
        // Instantiating the persistentStoreCoordinator property
        let coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent(SQLITE_FILE_NAME)
        var failureReason = "There was an error creating or loading the application's saved data."
        
        do {
            
            try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
            
        } catch {
            
            // Report any error
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        
        // Returns the managed object context for the application
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        
        managedObjectContext.persistentStoreCoordinator = coordinator
        
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                
                try managedObjectContext.save()
                
            } catch {
                
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
}
