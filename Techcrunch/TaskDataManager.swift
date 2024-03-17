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
            var taskList: [TaskInformation] = [] // TaskInformationの配列を初期化

            for taskDataStore in results {
                guard let taskName = taskDataStore.taskName,
                      let dueDate = taskDataStore.dueDate, // NSDateからDateへの自動変換を利用
                      let belongedClassName = taskDataStore.belongClassName,
                      let taskURL = taskDataStore.taskURL else {
                    continue // 必要な情報が不足している場合はこのタスクをスキップ
                }
                
                let taskId = Int(taskDataStore.taskId) // Int16からIntへの変換
                let hasSubmitted = taskDataStore.hasSubmitted
                
                // 通知タイミングの処理。TaskDataStoreから直接Date配列への変換方法は、
                // TaskDataStoreのnotificationTiming属性の型や保存形式に依存します。
                // 以下は、NSArrayを[Date]?に変換する疑似コードであり、実際の変換方法は実装によります。
                var notificationTiming: [Date]? = nil
                if let notificationArray = taskDataStore.notificationTiming as? [Date] {
                    notificationTiming = notificationArray
                }
                
                // TaskInformationインスタンスの作成
                let taskInfo = TaskInformation(
                    taskName: taskName,
                    dueDate: dueDate,
                    belongedClassName: belongedClassName,
                    taskURL: taskURL,
                    hasSubmitted: hasSubmitted,
                    notificationTiming: notificationTiming,
                    taskId: taskId
                )
                
                // 変換したTaskInformationを配列に追加
                taskList.append(taskInfo)
            }

            // 処理が完了したら、クラスレベルのtaskListプロパティに結果を格納
            self.taskList = taskList
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
                    //insertTaskDataIntoDB(taskData: taskData)
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
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            
            for taskInfo in taskList {
                let dueDateString = dateFormatter.string(from: taskInfo.dueDate)
                if !isExist(name: taskInfo.taskName) {
                    addTaskData(taskName: taskInfo.taskName, dueDate: dueDateString, belongedClassName: taskInfo.belongedClassName, taskURL: taskInfo.taskURL)
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
    
    func insertTaskDataIntoDB(taskList: [TaskInformation]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for taskInfo in taskList {
            // 新しいタスクがすでに存在するかどうかを確認
            let fetchRequest: NSFetchRequest<TaskDataStore> = TaskDataStore.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "taskName == %@", taskInfo.taskName)
            
            do {
                let existingTasks = try context.fetch(fetchRequest)
                if existingTasks.isEmpty {
                    // 重複するタスクが存在しない場合のみ新しいエンティティを作成
                    let newTaskDataStore = TaskDataStore(context: self.context)
                    // TaskDataStoreエンティティの総数を取得して、新しいtaskIdを設定
                    let totalTasksCount = try context.count(for: TaskDataStore.fetchRequest())
                    newTaskDataStore.taskId = Int16(totalTasksCount - 1)
                    
                    newTaskDataStore.belongClassName = taskInfo.belongedClassName
                    newTaskDataStore.taskName = taskInfo.taskName
                    newTaskDataStore.dueDate = taskInfo.dueDate
                    newTaskDataStore.taskURL = taskInfo.taskURL
                    newTaskDataStore.hasSubmitted = taskInfo.hasSubmitted
                    
                    if let notificationTiming = taskInfo.notificationTiming, !notificationTiming.isEmpty {
                        let notificationTimesStringArray = notificationTiming.map { dateFormatter.string(from: $0) }
                        newTaskDataStore.notificationTiming = notificationTimesStringArray as NSArray
                    }
                    
                    // コンテキストを保存
                    try context.save()
                    print("タスク '\(taskInfo.taskName)' をデータベースに追加しました。")
                } else {
                    // 重複するタスクが存在する場合、必要に応じて処理を行う
                    print("タスク '\(taskInfo.taskName)' はすでに存在しています。")
                }
            } catch {
                print("データベースの操作中にエラーが発生しました: \(error)")
            }
        }
        
        // 最後にすべてのタスクを表示
        fetchAndPrintAllTaskDataStore()
    }

    
    func fetchAndPrintAllTaskDataStore() {
        let fetchRequest: NSFetchRequest<TaskDataStore> = TaskDataStore.fetchRequest()

        do {
            // コンテキストからTaskDataStoreの全データをフェッチ
            let tasks = try context.fetch(fetchRequest)
            print("TaskDataStoreの中身")
            // フェッチした各タスクの詳細を出力
            for task in tasks {
                print("""
                    タスクID: \(task.taskId),
                    タスク名: \(task.taskName ?? "不明"),
                    所属クラス名: \(task.belongClassName ?? "不明"),
                    期限: \((task.dueDate as Date?)?.description ?? "不明"),
                    URL: \(task.taskURL ?? "不明"),
                    提出済み: \(task.hasSubmitted ? "はい" : "いいえ"),
                    通知タイミング: \(task.notificationTiming?.description ?? "未設定")
                    """)
            }
        } catch {
            print("フェッチ中にエラーが発生しました: \(error)")
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
