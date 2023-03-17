//
//  My_Walk+CoreDataProperties.swift
//  walking-project
//
//  Created by Junwon Jang on 2023/03/17.
//
//

import Foundation
import CoreData


extension My_Walk {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<My_Walk> {
        return NSFetchRequest<My_Walk>(entityName: "My_Walk")
    }

    @NSManaged public var calories: Int64
    @NSManaged public var current_point: Int64
    @NSManaged public var distance: Double
    @NSManaged public var my_id: UUID?
    @NSManaged public var total_walk: Int64

}

extension My_Walk : Identifiable {

}
