//
//  My_Walk+CoreDataClass.swift
//  walking-project
//
//  Created by GMC on 2023/03/17.
//
//

import Foundation
import CoreData

@objc(My_Walk)
public class My_Walk: NSManagedObject {
    class func sharedInstance(context: NSManagedObjectContext) -> My_Walk {
        let entityName = String(describing: My_Walk.self)
        let fetchRequest = NSFetchRequest<My_Walk>(entityName: entityName)
        fetchRequest.fetchLimit = 1
        
        do {
            if let object = try context.fetch(fetchRequest).first {
                return object
            } else {
                let object = My_Walk(context: context)
                // Initialize any default values here
                return object
            }
        } catch {
            fatalError("Unresolved error: \(error)")
        }
    }
}
