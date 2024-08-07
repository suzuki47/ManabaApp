//
//  TaskDataStore+CoreDataProperties.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2024/06/24.
//
//

import Foundation
import CoreData


extension TaskDataStore {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskDataStore> {
        return NSFetchRequest<TaskDataStore>(entityName: "TaskDataStore")
    }

    @NSManaged public var belongClassName: String?
    @NSManaged public var dueDate: Date?
    @NSManaged public var hasSubmitted: Bool
    @NSManaged public var notificationTiming: NSArray?
    @NSManaged public var taskId: Int64
    @NSManaged public var taskName: String?
    @NSManaged public var taskURL: String?

}

extension TaskDataStore : Identifiable {

}
