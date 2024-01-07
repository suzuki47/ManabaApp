//
//  DataStore+CoreDataProperties.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2023/12/29.
//
//

import Foundation
import CoreData


extension DataStore {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DataStore> {
        return NSFetchRequest<DataStore>(entityName: "DataStore")
    }

    @NSManaged public var detail: String?
    @NSManaged public var done: Bool
    @NSManaged public var id: Int16
    @NSManaged public var notificationTiming: NSArray?
    @NSManaged public var subtitle: String?
    @NSManaged public var title: String?

}

extension DataStore : Identifiable {

}
