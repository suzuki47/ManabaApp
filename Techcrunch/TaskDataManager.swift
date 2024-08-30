import Foundation
import CoreData
import UserNotifications

class TaskDataManager: DataManager {
    var allTaskDataList: [TaskData] = []
    var taskList: [TaskData] = []
    var keptNotificationTiming: [TaskIdAndNotificationTiming] = []
    //TODO: overrideしていいの？
    override init(dataName: String, context: NSManagedObjectContext) {
        super.init(dataName: dataName, context: context)
    }
    
    func deletePastDueTasks(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<TaskDataStore> = TaskDataStore.fetchRequest()
        let now = Date()

        // Fetch tasks with dueDate before now
        fetchRequest.predicate = NSPredicate(format: "dueDate < %@", now as CVarArg)

        do {
            let pastDueTasks = try context.fetch(fetchRequest)
            for task in pastDueTasks {
                context.delete(task)
            }
            
            // Save the context to persist changes
            try context.save()
        } catch {
            print("Failed to fetch or delete past due tasks: \(error)")
        }
    }
    
    func loadTaskData() async {
        let fetchRequest: NSFetchRequest<TaskDataStore> = TaskDataStore.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
            print("データベースからのフェッチ結果数: \(results.count)")

            for (index, taskDataStore) in results.enumerated() {
                guard let taskName = taskDataStore.taskName,
                      let dueDate = taskDataStore.dueDate, // NSDateからDateへの自動変換を利用
                      let belongedClassName = taskDataStore.belongClassName,
                      let taskURL = taskDataStore.taskURL else {
                    print("データが不足しているため、タスク \(index) をスキップします")
                    continue // 必要な情報が不足している場合はこのタスクをスキップ
                }
                let taskId = taskDataStore.taskId
                
                let hasSubmitted = taskDataStore.hasSubmitted
                
                var notificationTiming: [Date]? = nil
                if let notificationArray = taskDataStore.notificationTiming as? [Date] {
                    notificationTiming = notificationArray
                }
                
                let taskInfo1 = TaskData(
                    taskName: taskName,
                    dueDate: dueDate,
                    belongedClassName: belongedClassName,
                    taskURL: taskURL,
                    //hasSubmitted: hasSubmitted,
                    hasSubmitted: false,
                    notificationTiming: notificationTiming,
                    taskId: Int(taskId)
                )
                
                print("タスク \(index) を TaskInformation に変換: \(taskInfo1)")

                allTaskDataList.append(taskInfo1)
            }
        } catch {
            print("タスクデータの読み込みに失敗しました: \(error)")
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
            // TODO: 以下の機能の代替
            /*
            for taskInfo in taskList {
                let dueDateString = dateFormatter.string(from: taskInfo.dueDate)
                if !isExist(name: taskInfo.taskName) {
                    addTaskData(taskName: taskInfo.taskName, dueDate: dueDateString, belongedClassName: taskInfo.belongedClassName, taskURL: taskInfo.taskURL)
                } else {
                    // 課題が存在する場合は、未提出に設定
                    makeTaskNotSubmitted(taskName: taskInfo.taskName)
                }
            }*/
        } catch {
            print("課題スクレーピング失敗！ TaskDataManager 116: \(error)")
        }
    }
    
    func insertTaskDataIntoDB(taskList: [TaskData]) {
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
                    
                    
                    newTaskDataStore.taskId = Int64(taskInfo.taskId)
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
}
