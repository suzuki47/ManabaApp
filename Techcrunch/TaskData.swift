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
        self.notificationTiming = []
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


/*
struct taskData {
    //let id: UUID
    let name: String
    let dueDate: Date
    let detail: String
    let taskType: Int
    // 通知日付が空でなければtrueを返す
    var isNotified: Bool {
        return !_notificationDates.isEmpty
    }
    private var _notificationDates: [Date] = []
    //private var lastNotifiedDate: Date?
    
    // 通知日付の公開用の配列を返す
    var notificationDates: [Date] {
        return _notificationDates.map { $0 }
    }
    
    mutating func addNotificationDate(_ date: Date) {
        _notificationDates.append(date)
    }
    
    
    public init(name: String, dueDate: Date, detail: String, taskType: Int, isNotified: Bool = false) {
        //self.id = UUID()
        self.name = name
        self.dueDate = dueDate
        self.detail = detail
        self.taskType = taskType
    }
    
    /*init(from taskDataStore: TaskDataStore) {
            self.name = taskDataStore.name ?? ""
            self.dueDate = taskDataStore.dueDate ?? Date()
            self.detail = taskDataStore.detail ?? ""
            self.taskType = Int(taskDataStore.taskType)
            // 他のプロパティも必要に応じて変換して設定します
            self._notificationDates = [] // この部分はTaskDataStoreからの変換方法を具体的に指定する必要があります
    }*/
    
    // 指定されたインデックスの通知日付を削除する
    mutating func removeNotificationDate(at index: Int) {
        if index < _notificationDates.count {
            _notificationDates.remove(at: index)
        }
    }
    // すべての通知日付をクリアする
    mutating func clearNotificationDates() {
        self._notificationDates.removeAll()
    }
}

class TaskData {
    static let shared = TaskData()
    private init() {}
    
    var tasks: [taskData] = []
}

extension TaskData: CustomStringConvertible {
    var description: String {
        // tasksプロパティの内容を文字列で表現
        let tasksDescription = tasks.map { task in
            // ここで各taskの詳細を文字列にする
            return "Task(name: \(task.name), dueDate: \(task.dueDate), detail: \(task.detail), taskType: \(task.taskType))"
        }.joined(separator: ",\n")

        return "TaskData(tasks: [\n\(tasksDescription)\n])"
    }
}
*/
