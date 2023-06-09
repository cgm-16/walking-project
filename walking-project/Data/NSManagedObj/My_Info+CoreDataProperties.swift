//
//  My_Info+CoreDataProperties.swift
//  walking-project
//
//  Created by GMC on 2023/03/17.
//
//

import Foundation
import CoreData


extension My_Info {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<My_Info> {
        return NSFetchRequest<My_Info>(entityName: "My_Info")
    }

    @NSManaged public var height: Int16
    @NSManaged public var isFemale: Int16
    @NSManaged public var name: String?
    @NSManaged public var weight: Int16

}

extension My_Info : Identifiable {

}
