//
//  TaskDataStore+CoreDataProperties.swift
//  Techcrunch
//
//  Created by 鈴木悠太 on 2023/08/25.
//
//

import Foundation
import CoreData


extension TaskDataStore {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskDataStore> {
        return NSFetchRequest<TaskDataStore>(entityName: "TaskDataStore")
    }

    @NSManaged public var detail: String?
    @NSManaged public var dueDate: Date?
    @NSManaged public var name: String?
    @NSManaged public var taskType: Int16
    @NSManaged public var notificationDates: NSObject?
    @NSManaged public var isNotified: Bool

}

extension TaskDataStore : Identifiable {

}
/*extension TaskDataStore {
    func toTaskData() -> TaskData {
        var taskData = TaskData(
            name: self.name ?? "",
            dueDate: self.dueDate ?? Date(),
            detail: self.detail ?? "",
            taskType: Int(self.taskType),
            isNotified: self.isNotified
        )

        // Convert notificationDates from NSObject to [Date]
        if let data = self.notificationDates as? Data {
            if let dates = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Date] {
                for date in dates {
                    taskData.addNotificationDate(date)
                }
            }
        }

        return taskData
    }
}*/

