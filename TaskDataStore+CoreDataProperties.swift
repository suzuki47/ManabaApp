//
//  TaskDataStore+CoreDataProperties.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2024/02/06.
//
//

import Foundation
import CoreData


extension TaskDataStore {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskDataStore> {
        return NSFetchRequest<TaskDataStore>(entityName: "TaskDataStore")
    }

    @NSManaged public var belongClassId: Int16
    @NSManaged public var dueDate: Date?
    @NSManaged public var hasSubmitted: Bool
    @NSManaged public var notificationTiming: NSArray?
    @NSManaged public var taskId: Int16
    @NSManaged public var taskName: String?
    @NSManaged public var taskURL: String?

}

extension TaskDataStore : Identifiable {

}
