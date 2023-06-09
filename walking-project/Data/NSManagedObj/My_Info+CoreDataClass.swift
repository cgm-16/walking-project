//
//  My_Info+CoreDataClass.swift
//  walking-project
//
//  Created by GMC on 2023/03/17.
//
//

import Foundation
import CoreData

@objc(My_Info)
public class My_Info: NSManagedObject {
    class func sharedInstance(context: NSManagedObjectContext) -> My_Info {
        let entityName = String(describing: My_Info.self)
        let fetchRequest = NSFetchRequest<My_Info>(entityName: entityName)
        fetchRequest.fetchLimit = 1
        
        do {
            if let object = try context.fetch(fetchRequest).first {
                return object
            } else {
                let object = My_Info(context: context)
                // Initialize any default values here
                return object
            }
        } catch {
            fatalError("Unresolved error: \(error)")
        }
    }
}
