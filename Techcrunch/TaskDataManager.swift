import Foundation
import CoreData
import UserNotifications

class TaskDataManager: DataManager {
    //private var notificationAdapterBag: [Int: NotificationCustomAdapter] = [:]
    var allTaskDataList: [TaskData] = []
    //private var formatter: DateFormatter?
    var taskList: [TaskInformation] = []
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
                      let taskURL = taskDataStore.taskURL,
                      let belongedClassName = taskDataStore.belongClassName
                else {
                    continue
                }
                
                let hasSubmitted = taskDataStore.hasSubmitted
                
                // 現在時刻との比較
                if dueDate > Date() {
                    let taskData = TaskData(taskId: taskId, belongedClassName: belongedClassName, taskName: taskName, dueDate: dueDate, taskURL: taskURL, hasSubmitted: hasSubmitted)
                    
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
                // 該当するClassDataを名前で検索し、タスクを追加
                let className = taskData.belongedClassName
                if let classData = DataManager.classDataList.first(where: { $0.className == className }) {
                    classData.addTask(taskData)
                } else {
                    print("Warning: ClassData with name \(className) does not exist.")
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
                if DataManager.classDataList.contains(where: { $0.className == belongedClassName }) {
                    let taskData = TaskData(taskId: dataCount, belongedClassName: belongedClassName, taskName: taskName, dueDate: dueDateTime, taskURL: taskURL, hasSubmitted: false)
                    dataCount = (dataCount + 1) % 99999999
                    
                    let defaultTiming = Calendar.current.date(byAdding: .hour, value: -1, to: dueDateTime)!
                    taskData.addNotificationTiming(defaultTiming)
                    
                    allTaskDataList.append(taskData)
                    if let classData = DataManager.classDataList.first(where: { $0.className == belongedClassName }) {
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
        let urlList = [
            "https://ct.ritsumei.ac.jp/ct/home_summary_query",
            "https://ct.ritsumei.ac.jp/ct/home_summary_survey",
            "https://ct.ritsumei.ac.jp/ct/home_summary_report"
        ]
        let SVC = await SecondViewController()
        let cookieString = await SVC.assembleCookieString()
        let scraper = ManabaScraper(cookiestring: cookieString)
        print("授業スクレイピングテスト（時間割以外）：スタート")
        
        do {
            self.taskList = try await scraper.scrapeTaskDataFromManaba(urlList: urlList, cookieString: cookieString)
            print("授業スクレイピングテスト（時間割以外）：フィニッシュ")
            
            for taskInfo in taskList {
                if !isExist(name: taskInfo.taskName) {
                    addTaskData(taskName: taskInfo.taskName, dueDate: taskInfo.deadline, belongedClassName: taskInfo.belongedClassName, taskURL: taskInfo.taskURL)
                } else {
                    // 課題が存在する場合は、未提出に設定
                    makeTaskNotSubmitted(taskName: taskInfo.taskName)
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
        newTaskDataStore.belongClassName = taskData.belongedClassName
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
