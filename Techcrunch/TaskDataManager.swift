import Foundation
import CoreData
import UserNotifications

class TaskDataManager: DataManager {
    //private var notificationAdapterBag: [Int: NotificationCustomAdapter] = [:]
    private var allTaskDataList: [TaskData] = []
    //private var formatter: DateFormatter?
    
    //TODO: overrideしていいの？
    override init(dataName: String, context: NSManagedObjectContext) {
        super.init(dataName: dataName, context: context)
        // DataManagerのprepareForWorkはsuper.init内で呼ばれるため、ここでは不要
        //self.notificationAdapterBag = [:]
        self.allTaskDataList = []
        //self.formatter = DateFormatter()
        //self.formatter?.dateFormat = "yyyy-MM-dd HH:mm"
        //self.formatter?.locale = Locale(identifier: "ja_JP")
    }
    
    func loadTaskData() {
        let fetchRequest: NSFetchRequest<TaskDataStore> = TaskDataStore.fetchRequest()
        
        do {
            let results = try context.fetch(fetchRequest)
            allTaskDataList.removeAll()
            
            for taskDataStore in results {
                guard let taskId = taskDataStore.taskId as? Int,
                      let taskName = taskDataStore.taskName,
                      let dueDate = taskDataStore.dueDate,
                      let taskURL = taskDataStore.taskURL else {
                    continue
                }
                
                let belongedClassId = Int(taskDataStore.belongClassId) // Core DataはInt16を使用するためキャスト
                let hasSubmitted = taskDataStore.hasSubmitted
                
                // 現在時刻との比較
                if dueDate > Date() {
                    let taskData = TaskData(taskId: taskId, belongedClassId: belongedClassId, taskName: taskName, dueDate: dueDate, taskURL: taskURL, hasSubmitted: hasSubmitted)
                    
                    // 通知タイミングの処理
                    if let notificationTimingArray = taskDataStore.notificationTiming as? [Date] {
                        for timing in notificationTimingArray {
                            taskData.addNotificationTiming(timing)
                        }
                    }
                    
                    // allTaskDataListに追加
                    allTaskDataList.append(taskData)
                } else {
                    // 締切日時が過ぎているタスクは削除
                    context.delete(taskDataStore)
                }
            }
            
            try context.save()
        } catch {
            print("タスクデータの読み込みに失敗しました: \(error)")
        }
    }
    func setTaskDataIntoClassData() {
        for taskData in allTaskDataList {
            if !taskData.hasSubmitted {
                // 該当するClassDataを探し、タスクを追加
                let classId = taskData.belongedClassId
                if classId < DataManager.classDataList.count {
                    DataManager.classDataList[classId].addTask(taskData)
                } else {
                    print("Warning: ClassData with id \(classId) does not exist.")
                }
            }
        }
    }
    
    func sortAllTaskDataList() {
        allTaskDataList.sort { (task1, task2) -> Bool in
            // 提出状態（hasSubmitted）がtrueのものを先にする
            if task1.hasSubmitted != task2.hasSubmitted {
                return task2.hasSubmitted // hasSubmittedがtrueのものが先にくるようにする
            }
            
            // 提出状態が同じ場合は、締切日（dueDate）が早い順にする
            return task1.dueDate < task2.dueDate
        }
    }
    
    func getAllTaskDataList() -> [TaskData] {
        return allTaskDataList
    }
    /* 2/8
    func addAdapter(num: Int, adapter: NotificationCustomAdapter) {
        notificationAdapterBag[num] = adapter
    }
     */
    //TODO:
    func addTaskData(taskName: String, dueDate: String, belongedClassName: String, taskURL: String) {
        // DateFormatterの設定
        formatter?.dateFormat = "yyyy-MM-dd HH:mm"
        guard let dueDateTime = formatter?.date(from: dueDate) else {
            print("デフォルトの通知タイミングを設定できませんでした。")
            return
        }
        
        if isExist(name: taskName) {
            // 既に存在する場合は未提出判定に
            makeTaskNotSubmitted(taskName: taskName)
        } else {
            let now = Date()
            if dueDateTime > now {
                // 提出期限が過ぎていなければ
                let classId = searchClassId(belongedClassName: belongedClassName)
                if classId != -1 {
                    let taskData = TaskData(taskId: dataCount, belongedClassId: classId, taskName: taskName, dueDate: dueDateTime, taskURL: taskURL, hasSubmitted: false)
                    dataCount = (dataCount + 1) % 99999999
                    
                    let defaultTiming = Calendar.current.date(byAdding: .hour, value: -1, to: dueDateTime)!
                    taskData.addNotificationTiming(defaultTiming)
                    
                    // 通知設定のリクエスト（Javaの機能に相当する部分をSwiftに置き換える。以下はダミーの実装例）
                    // requestSettingNotification(dataName: dataName, taskId: taskData.taskId, taskName: taskName, dueDate: dueDate, defaultTiming: defaultTiming)
                    
                    allTaskDataList.append(taskData)
                    if let classData = DataManager.classDataList.first(where: { $0.classId == classId }) {
                        classData.addTask(taskData)
                    }
                    insertTaskDataIntoDB(taskData: taskData)
                }
            } else {
                print("\(taskName)は提出期限を過ぎていたので追加しません")
            }
            sortAllTaskDataList()
        }
    }
    
    func isExist(name: String) -> Bool {
        return allTaskDataList.contains { $0.taskName == name }
    }
    
    func searchClassId(belongedClassName: String) -> Int {
        if let classData = DataManager.classDataList.first(where: { $0.className == belongedClassName }) {
            return classData.classId
        } else {
            print("\(belongedClassName)はありませんでした。")
            return -1
        }
    }
    //TODO:
    func deleteTaskNotification() {
        
    }
    
    func deleteFinishedTaskNotification() {
        
    }
    //TODO: addTaskData実装後に実装する
    func getTaskDataFromManaba() async {
        do {
            let taskList = try await ManabaScraper(cookiestring: "YourCookieString").scrapeTaskDataFromManaba()
            print("課題スクレーピング完了！ TaskDataManager 104")
            for (assignmentName, deadline) in taskList {
                print("\(assignmentName) TaskDataManager 106")
                if !isExist(name: assignmentName) {
                    print("\(assignmentName) 持ってないから追加するよー！ TaskDataManager 110")
                    addTaskData(taskName: assignmentName, dueDate: deadline, belongedClassName: "授業名", taskURL: "課題提出URL")
                    print("\(assignmentName) 追加したよー！ TaskDataManager 112")
                } else {
                    if let index = allTaskDataList.firstIndex(where: { $0.taskName == assignmentName }) {
                        allTaskDataList[index].changeSubmitted(false)
                    }
                }
            }
        } catch {
            print("課題スクレーピング失敗！ TaskDataManager 116: \(error)")
        }
    }
    
    func makeAllTasksSubmitted() {
        for i in 0..<allTaskDataList.count {
            allTaskDataList[i].changeSubmitted(true)
        }
    }
    
    func makeTaskNotSubmitted(taskName: String) {
        for i in 0..<allTaskDataList.count {
            if allTaskDataList[i].taskName == taskName {
                allTaskDataList[i].changeSubmitted(false)
                break // 最初に見つかったタスクのみ状態を変更し、ループを抜ける
            }
        }
    }
    
    func insertTaskDataIntoDB(taskData: TaskData) {
        // 新しいTaskDataStoreエンティティのインスタンスを作成
        let newTaskDataStore = TaskDataStore(context: self.context)
        
        // TaskDataStoreエンティティのプロパティを設定
        newTaskDataStore.taskId = Int16(taskData.taskId)
        newTaskDataStore.belongClassId = Int16(taskData.belongedClassId)
        newTaskDataStore.taskName = taskData.taskName
        newTaskDataStore.dueDate = taskData.dueDate
        newTaskDataStore.taskURL = taskData.taskURL
        newTaskDataStore.hasSubmitted = taskData.hasSubmitted
        
        // 通知タイミングの配列を適切な形式に変換して保存
        if !taskData.notificationTiming.isEmpty {
            // DateFormatterを使用してDateを文字列に変換
            self.formatter?.dateFormat = "yyyy-MM-dd HH:mm"
            let notificationTimesString = taskData.notificationTiming.compactMap { formatter?.string(from: $0) }.joined(separator: ", ")
            // TaskDataStoreにnotificationTimingを保存する方法を適用（例：カスタム属性または関連エンティティを使用）
        }
        
        // コンテキストを保存して変更を永続化ストアに反映
        do {
            try self.context.save()
            print("\(dataName)に\(taskData.taskName)を追加しました。")
        } catch {
            print("\(dataName)に追加失敗: \(error)")
        }
    }
    
    func addNotificationTiming() {
        
    }
    
    func updateNotificationTimingFromDB() {
        
    }
    
    func requestSettingNotification() {
        
    }
    
    func equestCancelNotification() {
        
    }
    
    func deleteFinishedNotification() {
        
    }
    
    func deleteNotification() {
        
    }
}
