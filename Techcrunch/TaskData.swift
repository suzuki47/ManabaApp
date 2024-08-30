import Foundation
import CoreData

class TaskData {
    var taskName: String //課題名
    var dueDate: Date //締切日時
    var belongedClassName: String //どのClassDataに所属しているか
    var taskURL: String //課題ページのURL
    var hasSubmitted: Bool //課題の提出の有無
    var notificationTiming: [Date]? //通知日時
    var taskId: Int //課題の識別子
    
    init(taskName: String, dueDate: Date,  belongedClassName: String, taskURL: String, hasSubmitted: Bool, notificationTiming: [Date]?, taskId: Int) {
        self.taskName = taskName
        self.dueDate = dueDate
        self.belongedClassName = belongedClassName
        self.taskURL = taskURL
        self.hasSubmitted = hasSubmitted
        self.notificationTiming = notificationTiming
        self.taskId = taskId
    }
    
    // Getter メソッド
    func getTaskId() -> Int {
        return self.taskId
    }
    
    func getBelongedClassName() -> String {
        return self.belongedClassName
    }
    
    func getTaskName() -> String {
        return self.taskName
    }
    
    func getDueDate() -> Date {
        return self.dueDate
    }
    
    func getNotificationTiming() -> [Date]? {
        return self.notificationTiming
    }
    
    func getTaskURL() -> String {
        return self.taskURL
    }
    
    func getHasSubmitted() -> Bool {
        return self.hasSubmitted
    }
    
    // メソッド
    func changeSubmitted(_ hasSubmitted: Bool) {
        self.hasSubmitted = hasSubmitted
    }
    
    func addNotificationTiming(_ newTiming: Date) {
        if self.notificationTiming == nil {
            self.notificationTiming = [newTiming]
        } else {
            self.notificationTiming?.append(newTiming)
            reorderNotificationTiming()
        }
    }
    
    func deleteNotificationTiming(at index: Int) {
        guard let notificationTiming = self.notificationTiming, index >= 0 && index < notificationTiming.count else { return }
        self.notificationTiming?.remove(at: index)
        reorderNotificationTiming()
    }
    
    func deleteFinishedNotification() {
        guard var notificationTiming = self.notificationTiming, !notificationTiming.isEmpty else { return }
        notificationTiming.removeFirst()
        reorderNotificationTiming()
    }
    
    func reorderNotificationTiming() {
        self.notificationTiming?.sort { $0 < $1 }
    }
    
    func replaceTaskName(_ taskName: String) {
        self.taskName = taskName
    }
    
    func replaceDueDate(_ dueDate: Date) {
        self.dueDate = dueDate
    }
}
