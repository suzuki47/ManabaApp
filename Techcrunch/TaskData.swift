import Foundation

struct taskData {
    let id: UUID
    let name: String
    let dueDate: Date
    let detail: String
    let taskType: Int
    // 通知日付が空でなければtrueを返す
    var isNotified: Bool {
        return !_notificationDates.isEmpty
    }
    private var _notificationDates: [Date] = []
    private var lastNotifiedDate: Date?
    
    // 通知日付の公開用の配列を返す
    var notificationDates: [Date] {
        return _notificationDates.map { $0 }
    }
    
    mutating func addNotificationDate(_ date: Date) {
        _notificationDates.append(date)
    }
    
    
    public init(name: String, dueDate: Date, detail: String, taskType: Int, isNotified: Bool = false) {
        self.id = UUID()
        self.name = name
        self.dueDate = dueDate
        self.detail = detail
        self.taskType = taskType
    }
    
    init(from taskDataStore: TaskDataStore) {
            self.id = taskDataStore.id ?? UUID()
            self.name = taskDataStore.name ?? ""
            self.dueDate = taskDataStore.dueDate ?? Date()
            self.detail = taskDataStore.detail ?? ""
            self.taskType = Int(taskDataStore.taskType)
            // 他のプロパティも必要に応じて変換して設定します
            self._notificationDates = [] // この部分はTaskDataStoreからの変換方法を具体的に指定する必要があります
        }
    
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

