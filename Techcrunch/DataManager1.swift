//
//  DataManager.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2023/11/01.
//
/*
import Foundation
import CoreData

class DataManager1 {
    var dataName: String = ""
    static var dataCount: Int = 0
    static var dataList: [Data] = []
    var headers: [String] = []
    var classroomInfo: [String] = []
    
    static let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MyDataModel") // あなたのCoreDataモデルの名前に置き換えてください
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // エラー処理を適切に行う
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // TaskDataStoreエンティティのすべてのインスタンスをCore Dataから取得する
    static func getDataStores() -> [DataStore] {
        let context = persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DataStore")
        
        do {
            let dataStores = try context.fetch(request) as! [DataStore]
            return dataStores
        } catch {
            print("Failed to fetch TaskDataStores: \(error.localizedDescription)")
            fatalError("Failed to fetch TaskDataStores: \(error)")
        }
    }
    
    // TaskDataStoreから取得したデータをTaskDataの共有インスタンスに反映する
    static func updateTaskDataFromCoreData() {
        let taskDataStores = getDataStores()
        var newTasks: [taskData] = []
        
        for taskDataStore in taskDataStores {
            var task = taskData(
                name: taskDataStore.name ?? "",
                dueDate: taskDataStore.dueDate ?? Date(),
                detail: taskDataStore.detail ?? "",
                taskType: Int(taskDataStore.taskType)
            )
            
            // 通知日を設定するロジックをここに追加する。
            // 例: task.addNotificationDate(date)
            
            newTasks.append(task)
        }
        
        // TaskData.shared.tasksを新しいタスクの配列で更新する
        TaskData.shared.tasks = newTasks
    }
    
    static func saveSharedTaskData() {
        let context = persistentContainer.viewContext
        
        // TaskData.shared.tasksの各タスクをTaskDataStoreに保存または更新する
        for task in TaskData.shared.tasks {
            // 既存のTaskDataStoreを検索するか、新しいエンティティを作成する
            let request = NSFetchRequest<DataStore>(entityName: "DataStore")
            request.predicate = NSPredicate(format: "name == %@", task.name)
            let results = try? context.fetch(request)
            
            let taskDataStore = results?.first ?? DataStore(context: context)
            
            // TaskDataのプロパティをTaskDataStoreにコピーする
            taskDataStore.name = task.name
            taskDataStore.dueDate = task.dueDate
            taskDataStore.detail = task.detail
            taskDataStore.taskType = Int16(task.taskType)
        }
        
        // 変更を保存する
        do {
            try context.save()
            print("セーブしました")
        } catch {
            // エラーハンドリング
            print("Error saving context: \(error)")
        }
    }
    
    static func removeData(at index: Int) {
        guard index >= 0 && index < TaskData.shared.tasks.count else {
            print("Index out of bounds")
            return
        }
        
        let taskToRemove = TaskData.shared.tasks[index]
        let context = persistentContainer.viewContext
        
        // Core Dataから該当するTaskDataStoreを削除する
        let fetchRequest: NSFetchRequest<DataStore> = DataStore.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", taskToRemove.name)
        
        if let results = try? context.fetch(fetchRequest), let objectToDelete = results.first {
            context.delete(objectToDelete)
        }
        
        // Sharedからタスクを削除する
        TaskData.shared.tasks.remove(at: index)
        
        // 変更を保存する
        do {
            try context.save()
        } catch {
            print("Error saving context after deleting task: \(error)")
        }
    }
    
    static func addNewTaskAndSave(name: String, dueDate: Date, detail: String, taskType: Int) {
        // 新しいタスクを作成
        let newTask = taskData(name: name, dueDate: dueDate, detail: detail, taskType: taskType, isNotified: false)
        
        // 新しいタスクをsharedタスクリストに追加
        TaskData.shared.tasks.append(newTask)
        
        // タスクの並び替え
        TaskData.shared.tasks.sort { $0.dueDate < $1.dueDate }
        
        // 変更をCore Dataに保存
        DataManager.saveSharedTaskData()
        
        // 通知をスケジュール
        //scheduleTaskNotification(for: name, at: dueDate.addingTimeInterval(-3600))
    }
    
    static func updateTask(name: String, newDetail: String, newDueDate: Date, newTaskType: Int) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<DataStore> = DataStore.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let taskToUpdate = results.first {
                // TaskDataStoreのプロパティを更新する
                taskToUpdate.detail = newDetail
                taskToUpdate.dueDate = newDueDate
                taskToUpdate.taskType = Int16(newTaskType)
                
                // ここに通知日時を更新するコードを追加する場合
                // taskToUpdate.notificationDates = ...
                
                // 変更を保存する
                try context.save()
                print("Updated task successfully.")
            } else {
                print("No task found with name: \(name)")
            }
        } catch {
            print("Error updating task: \(error.localizedDescription)")
        }
    }
    
    static func getDataFromManaba(){
        
        print("ggggg")
        //let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        var cookiestring = ""
        var header: [String] = []
        var classroomInfo: [String] = []
        
        // 取得したクッキーを「name=value;」に変形する
        /*cookieStore.getAllCookies { cookies in
            for cookie in cookies {
                cookiestring+=cookie.name
                cookiestring+="="
                cookiestring+=cookie.value
                cookiestring+=";"
            }
        }
        var hasCookie = false
        cookieStore.getAllCookies { cookies in
            for cookie in cookies {
                /*print("クッキー名: \(cookie.name), 値: \(cookie.value)")*/
                if cookie.name == "sessionid" {
                    hasCookie = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // webViewを閉じる
                        //webView.removeFromSuperview()
                        let stringValue = cookiestring
                        // HTMLParserクラスのインスタンスを作成し、クッキー文字列として'stringValue'を渡す
                        let htmlParser = ManabaScraper(cookiestring: stringValue)
                        
                        Task {
                            do {
                                let headers = try await htmlParser.parse()
                                header = headers
                                
                                let classroomInfoData = try await htmlParser.fetchClassroomInfo(usingCookie: stringValue)
                                classroomInfo = classroomInfoData
                                print("oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo")
                                print(classroomInfo)
                                //let classData = ClassData()
                                parseAndStoreClassData(dataList: classroomInfo)
                                for (index, day) in ClassData.classData.enumerated() {
                                    let dayName: String
                                    switch index {
                                    case 0: dayName = "月曜日"
                                    case 1: dayName = "火曜日"
                                    case 2: dayName = "水曜日"
                                    case 3: dayName = "木曜日"
                                    case 4: dayName = "金曜日"
                                    case 5: dayName = "土曜日"
                                    case 6: dayName = "日曜日"
                                    default: continue // 土曜日と日曜日は無視する
                                    }
                                    
                                    let classes = day.map { $0.description }
                                    print("\(dayName): \(classes)")
                                }
                                
                                DispatchQueue.main.async {
                                    let originalString = headers.joined(separator: " ")
                                    
                                    
                                    
                                    //let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SecondViewControllerID") as! SecondViewController
                                    //viewController.modalPresentationStyle = .fullScreen
                                    //viewController.headers = self.headers
                                    //viewController.classroomInfoData = self.classroomInfo // ここでデータを渡す
                                    //self.present(viewController, animated: true, completion: nil)
                                }
                            } catch {
                                print("Failed: \(error)")
                            }
                        }
                        
                        
                    }
                    
                }
            }
        }*/
    }
    
    
}
*/
