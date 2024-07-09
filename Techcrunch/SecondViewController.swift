//
//  SecondViewController.swift
//  Techcrunch
//
//  Created by 鈴木悠太 on 2023/07/10.
//

import Foundation
import UIKit
import UserNotifications
import CoreData
import WebKit

class SecondViewController: UIViewController, UITableViewDelegate, WKNavigationDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource, ClassInfoPopupDelegate, UIViewControllerTransitioningDelegate, DatePickerViewControllerDelegate {
    var collectionView: UICollectionView!
    var currentClassroomLabel: UILabel!
    //var classes: [ClassData] = []
    var context: NSManagedObjectContext!
    //var headers: [String] = []
    var cookies: [HTTPCookie]?
    //var classList: [ClassData] = []
    var professorList: [ClassAndProfessor] = []
    //var unregisteredClassList: [UnregisteredClassInformation] = []
    //var taskList: [TaskData] = []
    //var allTaskDataList: [TaskData] = []
    var activeDays: [String] = []
    var maxPeriod = 0
    var collectionViewHeightConstraint: NSLayoutConstraint?
    var showNotificationsButton: UIButton!
    var managedObjectContext: NSManagedObjectContext!
    
    // unregisteredClassListにはあるが、changeableClassesに同じnameのものがないデータを格納するための変数
    var classesToRegister = [UnregisteredClassInformation]()
    var tableView: UITableView!
    var classDataManager: ClassDataManager!
    var taskDataManager: TaskDataManager!
    
    override func viewDidLoad() {
        print("Starting viewDidLoad in SecondViewController")
        super.viewDidLoad()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    managedObjectContext = appDelegate.managedObjectContext
                }
        
        setupCurrentClassroomLabel()
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout) // frameを.zeroに設定
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ClassCollectionViewCell.self, forCellWithReuseIdentifier: "ClassCell")
        collectionView.backgroundColor = UIColor.white
        collectionView.translatesAutoresizingMaskIntoConstraints = false // Auto Layoutを使うために必要
        self.view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: currentClassroomLabel.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 200) // 適当な初期値
        collectionViewHeightConstraint?.isActive = true
        
        // collectionViewの背景色を黒に設定
        collectionView.backgroundColor = UIColor.white
        
        // セル間のスペースを設定
        layout.minimumInteritemSpacing = 1 // アイテム間のスペース（縦）
        layout.minimumLineSpacing = 1 // 行間のスペース（横）
        
        //self.updateActiveDaysAndMaxPeriod()
        updateCollectionViewHeight()
        
        // layoutの更新をトリガー
        collectionView.collectionViewLayout = layout
        
        // AppDelegate から context を取得
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            context = appDelegate.managedObjectContext
            print("Managed Object Context successfully retrieved: \(context!)")
        } else {
            fatalError("Failed to get context from AppDelegate")
        }
        
        // サンプル通知実験
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if granted {
                print("Notification authorization granted")
            } else {
                print("Notification authorization denied")
            }
        }
        NotifyManager.shared.removeAllNotifications()
        
        view.backgroundColor = UIColor(red: 0.5, green: 0.8, blue: 0.5, alpha: 1.0)
        print("Context: \(String(describing: context))")
        
        // TaskDataManagerのインスタンスを生成
        taskDataManager = TaskDataManager(dataName: "TaskData", context: context)
        //AddNotificationDialog.setTaskDataManager(taskDataManager)
        classDataManager = ClassDataManager(dataName: "ClassData", context: context)
        Task {
            classDataManager.loadClassData()
            //self.classList = classDataManager.classList
            self.updateActiveDaysAndMaxPeriod()
            await taskDataManager.loadTaskData()
            // ロードしたtaskListを一時的な配列にコピー
            var updatedTaskList = taskDataManager.taskList
            
            print("ロード後のクラスリストの内容確認（SecondViewController）:")
            for classInfo in classDataManager.classList {
                print("ClassId: \(classInfo.classId), DayAndPeriod: \(classInfo.dayAndPeriod), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName), 変更可能な授業か: \(classInfo.classIdChangeable), 通知のオンオフ: \(classInfo.isNotifying)")
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm" // 日付のフォーマットを設定
            
            print("ロード後のタスクリストの内容確認（SecondViewController）:")
            for classInfo in taskDataManager.taskList {
                let formattedDueDate = dateFormatter.string(from: classInfo.dueDate) // Date型をString型に変換
                let formattedNotificationTimings = classInfo.notificationTiming?.map { dateFormatter.string(from: $0) }.joined(separator: ", ") ?? "未設定" // 通知タイミングの配列を文字列に変換
                
                print("""
                  Task Name: \(classInfo.taskName),
                  Deadline: \(formattedDueDate),
                  Belonged Class Name: \(classInfo.belongedClassName),
                  Task URL: \(classInfo.taskURL),
                  Has Submitted: \(classInfo.hasSubmitted ? "Yes" : "No"),
                  Notification Timings: \(formattedNotificationTimings),
                  Task ID: \(classInfo.taskId)
                  """)
            }
            /*if !classDataManager.checkClassData() {
             classDataManager.resetClassData()
             }*/
            
            for classData in classDataManager.classList {
                if !classData.isNotifying {
                    let newStatus = ClassIdAndIsNotifying(classId: classData.classId, isNotifying: classData.isNotifying)
                    classDataManager.notificationStatus.append(newStatus)
                }
            }
            
            classDataManager.classList = classDataManager.classList.filter { $0.classIdChangeable }
            //var changeableClasses = classDataManager.classList.filter { $0.classIdChangeable }
            
            print("classIdChangeable=false削除後のクラスリストの内容確認（SecondViewController）:")
            for classInfo in classDataManager.classList {
                print("ClassId: \(classInfo.classId), DayAndPeriod: \(classInfo.dayAndPeriod), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName), 変更可能な授業か: \(classInfo.classIdChangeable), 通知のオンオフ: \(classInfo.isNotifying)")
            }
            await classDataManager.getChangeableClassDataFromManaba()
            print("unregisteredClassListの内容確認（SecondViewController）:")
            for classInfo in classDataManager.unregisteredClassList {
                print("ClassId: \(classInfo.classId),  授業名:\(classInfo.name),  URL: \(classInfo.url), 教授名: \(classInfo.professorName)")
            }
            for classData in classDataManager.classList {
                if classDataManager.unregisteredClassList.contains(where: { $0.classId == classData.classId }) {
                    classDataManager.classesToRegister.append(classData)
                }
            }
            print("classesToRegisterの内容確認（SecondViewController）:")
            for classInfo in classDataManager.classesToRegister {
                print("ClassId: \(classInfo.classId), DayAndPeriod: \(classInfo.dayAndPeriod), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName), 変更可能な授業か: \(classInfo.classIdChangeable), 通知のオンオフ: \(classInfo.isNotifying)")
            }
        
            await classDataManager.getUnChangeableClassDataFromManaba()
            await classDataManager.getProfessorNameFromManaba()
            
            classDataManager.classList.append(contentsOf: classDataManager.classesToRegister)
            classDataManager.classList.sort { (classInfo1, classInfo2) -> Bool in
                return classInfo1.dayAndPeriod < classInfo2.dayAndPeriod
            }
            for status in classDataManager.notificationStatus {
                for i in 0..<classDataManager.classList.count {
                    if classDataManager.classList[i].classId == status.classId {
                        classDataManager.classList[i].isNotifying = status.isNotifying
                    }
                }
            }
            print("完成版クラスリストの内容確認（SecondViewController）:")
            for classInfo in classDataManager.classList {
                print("ClassId: \(classInfo.classId), DayAndPeriod: \(classInfo.dayAndPeriod), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName), 変更可能な授業か: \(classInfo.classIdChangeable), 通知のオンオフ: \(classInfo.isNotifying)")
            }
            
            // ロードしたtaskListを一時的な配列にコピー
            updatedTaskList = taskDataManager.taskList
            /*
            // updatedTaskListの各要素に対して処理を行う
            for i in 0..<updatedTaskList.count {
                let task = updatedTaskList[i]
                // belongedClassNameがclassListのnameに存在しない、かつunregisteredClassListにも存在しないかチェック
                if !classDataManager.classList.contains(where: { $0.name == task.belongedClassName }) &&
                    !self.unregisteredClassList.contains(where: { $0.name == task.belongedClassName }) {
                    // 条件に一致する場合、belongedClassNameを"none"に更新
                    updatedTaskList[i].belongedClassName = "none"
                }
            }
            */
            // 処理が完了したら、更新したtaskListをself.taskListに代入
            //self.taskList = updatedTaskList
            print("belongedClassNameがclassListのnameに存在しない、かつunregisteredClassListにも存在しないかチェック後のタスクリストの内容確認（SecondViewController）:")
            for classInfo in taskDataManager.taskList {
                let formattedDueDate = dateFormatter.string(from: classInfo.dueDate) // Date型をString型に変換
                let formattedNotificationTimings = classInfo.notificationTiming?.map { dateFormatter.string(from: $0) }.joined(separator: ", ") ?? "未設定" // 通知タイミングの配列を文字列に変換
                
                print("""
                  Task Name: \(classInfo.taskName),
                  Deadline: \(formattedDueDate),
                  Belonged Class Name: \(classInfo.belongedClassName),
                  Task URL: \(classInfo.taskURL),
                  Has Submitted: \(classInfo.hasSubmitted ? "Yes" : "No"),
                  Notification Timings: \(formattedNotificationTimings),
                  Task ID: \(classInfo.taskId)
                  """)
            }
            // 未登録クラスのnameリストを作成
            //let unregisteredNames = Set(unregisteredClassList.map { $0.name })

            // changeableClassesから、unregisteredClassListに同じnameのものがないデータを削除
            //changeableClasses = changeableClasses.filter { unregisteredNames.contains($0.name) }

            // changeableClassesのnameリストを作成
            //let changeableNames = Set(changeableClasses.map { $0.name })
            /*
            // classesToRegisterに条件に合うものを追加
            for unregisteredClass in unregisteredClassList {
                if !changeableNames.contains(unregisteredClass.name) {
                    classesToRegister.append(unregisteredClass)
                }
            }*/
            

            //classDataManager.emptyMyClassDataStore()
            classDataManager.replaceClassDataIntoDB(classInformationList: classDataManager.classList)
            //self.unregisteredClassList = classDataManager.unregisteredClassList
            
            await taskDataManager.getTaskDataFromManaba()
            //taskList = taskDataManager.taskList
             
            // taskListの各タスクに対して処理を行う
            for i in 0..<taskDataManager.taskList.count {
                let task = taskDataManager.taskList[i]

                // updatedTaskListに同じtaskNameを持つタスクが存在するかチェック
                if !updatedTaskList.contains(where: { $0.taskName == task.taskName }) {
                    // 存在しない場合、hasSubmittedをtrueに設定
                    taskDataManager.taskList[i].hasSubmitted = true
                }
            }
            //let dateFormatter = DateFormatter()
            
            print("タスクリスト")
            print(taskDataManager.taskList)
            taskDataManager.insertTaskDataIntoDB(taskList: taskDataManager.taskList)
            //createSampleClassList()
            classDataManager.replaceClassDataIntoDB(classInformationList: classDataManager.classList)
            print("クラスリストの内容確認（SecondViewController）:")
            for classInfo in classDataManager.classList {
                print("ID: \(classInfo.dayAndPeriod), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName), 変更可能な授業か:\(classInfo.classIdChangeable)")
            }
            /*
            print("クラスリスト（未登録）の内容確認（SecondViewController）:")
            for classInfo in unregisteredClassList {
                print("Name: \(classInfo.name), Professor Name: \(classInfo.professorName), URL: \(classInfo.url)")
            }*/
            print("タスクリストの内容確認（SecondViewController）:")
            // DateFormatterの設定
            //let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm" // 日付のフォーマットを設定
            
            for classInfo in taskDataManager.taskList {
                let formattedDueDate = dateFormatter.string(from: classInfo.dueDate) // Date型をString型に変換
                let formattedNotificationTimings = classInfo.notificationTiming?.map { dateFormatter.string(from: $0) }.joined(separator: ", ") ?? "未設定" // 通知タイミングの配列を文字列に変換
                
                print("""
                      Task Name: \(classInfo.taskName),
                      Deadline: \(formattedDueDate),
                      Belonged Class Name: \(classInfo.belongedClassName),
                      Task URL: \(classInfo.taskURL),
                      Has Submitted: \(classInfo.hasSubmitted ? "Yes" : "No"),
                      Notification Timings: \(formattedNotificationTimings),
                      Task ID: \(classInfo.taskId)
                      """)
                
            }

            //print("allTaskDateList: \(taskDataManager.allTaskDataList)")
            //print("時間割に実装済みのその他の授業:\(changeableClasses)")
            print("時間割に未実装のその他の授業:\(classesToRegister)")
            self.updateActiveDaysAndMaxPeriod()
            updateCollectionViewHeight()
            setupTableView()
            
            print("通知直前のクラスリストの内容確認（SecondViewController）:")
            for classInfo in classDataManager.classList {
                print("ClassId: \(classInfo.classId), DayAndPeriod: \(classInfo.dayAndPeriod), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName), 変更可能な授業か: \(classInfo.classIdChangeable), 通知のオンオフ: \(classInfo.isNotifying)")
            }
            
            // クラスリストを処理して通知を追加
            for classInfo in classDataManager.classList {
                NotifyManager.shared.addClassNotifications(for: classInfo)
            }
           
            // タスクリストの通知を追加
            for task in taskDataManager.taskList {
                NotifyManager.shared.addTaskNotifications(for: task)
            }
            // 通知をスケジュール
            NotifyManager.shared.scheduleNotifications {
                // スケジュールされている通知を確認
                NotifyManager.shared.listScheduledNotifications()
            }
            // スケジュールされている通知を確認
            NotifyManager.shared.printNotifications()
            
            updateCurrentClassroomLabel()
            if let labelText = currentClassroomLabel.text {
                print("現在のクラスルームラベル: \(labelText)")
            } else {
                print("ラベルにテキストが設定されていません。")
            }
        }
        /*
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            self.setupShowNotificationsButton()
            self.view.bringSubviewToFront(self.showNotificationsButton)
        }*/
        /*
        // DispatchQueueを使用して非同期で実行
        DispatchQueue.global(qos: .userInitiated).async {
            /*taskDataManager.loadTaskData()
            print("TaskDataロード完了！ MainActivity 83")*/
            taskDataManager.setTaskDataIntoClassData()
            taskDataManager.sortAllTaskDataList()
            print("現在のコアデータ")
            //self.printCoreDataTaskData()
        }
         */
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            //self.resetCoreData()
        }
        print("Finished viewDidLoad in SecondViewController")
    }
    /* 使われていない
    // taskListに同じtaskNameがない場合のみ追加する関数
    func appendTaskIfNotExists(task: TaskInformation) {
        if !self.taskList.contains(where: { $0.taskName == task.taskName }) {
            self.taskList.append(task)
        }
    }
     */
    // taskURLからtaskIdを抽出する関数
    func extractTaskId(from url: String) -> Int? {
        let components = url.components(separatedBy: "_")
        var sevenDigitNumbers = [String]()
        
        for component in components {
            if component.count == 7, let _ = Int(component) {
                sevenDigitNumbers.append(component)
            }
        }
        
        if sevenDigitNumbers.count == 1 {
            // 7桁の数字が1つだけの場合、その数字を返す
            return Int(sevenDigitNumbers[0])
        } else if sevenDigitNumbers.count >= 2 {
            // 7桁の数字が2つ以上の場合、最初の2つを連結して14桁の数字を返す
            let concatenated = sevenDigitNumbers[0] + sevenDigitNumbers[1]
            return Int(concatenated)
        }
        
        return nil // 7桁の数字が見つからない場合
    }
    
    func removeNotificationTiming(_ date: Date, forTaskId taskId: Int) {
        if let index = taskDataManager.taskList.firstIndex(where: { $0.taskId == taskId }) {
            var timings = taskDataManager.taskList[index].notificationTiming ?? []
            
            // 通知タイミングの削除
            if let timingIndex = timings.firstIndex(of: date) {
                timings.remove(at: timingIndex)
                taskDataManager.taskList[index].notificationTiming = timings
                print("SecondViewController: taskListから通知タイミングが削除されました。")
            } else {
                print("SecondViewController: 通知タイミングが見つかりませんでした。")
            }
            
            // taskListの中身をプリントアウト
            print("Updated taskList after deletion:")
            printTaskList()
        } else {
            print("SecondViewController: タスクID: \(taskId) のタスクが見つかりませんでした。")
        }
    }

    func resetCoreData() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "TaskDataStore")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try managedObjectContext.execute(deleteRequest)
            try managedObjectContext.save()
            print("CoreData has been reset.")
        } catch let error as NSError {
            print("Could not reset CoreData: \(error), \(error.userInfo)")
        }
    }
    
    func printCoreDataTaskData() {
        let fetchRequest: NSFetchRequest<TaskDataStore> = TaskDataStore.fetchRequest()
        
        do {
            let tasks = try managedObjectContext.fetch(fetchRequest)
            for task in tasks {
                print("CoreData Task ID: \(task.taskId)")
                print("CoreData Task Name: \(task.taskName ?? "")")
                print("CoreData Due Date: \(task.dueDate ?? Date())")
                if let notificationTimings = task.notificationTiming as? [Date] {
                    for timing in notificationTimings {
                        print("CoreData Notification Timing: \(timing)")
                    }
                } else {
                    print("通知は設定されていません")
                }
            }
        } catch {
            print("Failed to fetch tasks from CoreData: \(error)")
        }
    }
    
    func printTaskList() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for task in taskDataManager.taskList {
            print("Task ID: \(task.taskId)")
            print("Task Name: \(task.taskName)")
            print("Due Date: \(dateFormatter.string(from: task.dueDate))")
            if let notificationTimings = task.notificationTiming {
                for timing in notificationTimings {
                    print("Notification Timing: \(dateFormatter.string(from: timing))")
                }
            } else {
                print("通知は設定されていません")

            }
        }
    }
    /* 使われていない
    func createSampleClassList() {
        // サンプルデータの作成
        classList.append(ClassData(classId: 8317000, dayAndPeriod: 4, name: "物理", room: "104教室", url: "https://ct.ritsumei.ac.jp/ct/course_8317000", professorName: "田中健", classIdChangeable: false, isNotifying: true))
        classList.append(ClassData(classId: 8317001, dayAndPeriod: 5, name: "生物", room: "105教室", url: "https://ct.ritsumei.ac.jp/ct/course_8317001", professorName: "中村聡", classIdChangeable: true, isNotifying: true))
        classList.append(ClassData(classId: 8317002, dayAndPeriod: 24, name: "ゼミ", room: "109教室", url: "https://ct.ritsumei.ac.jp/ct/course_8317002", professorName: "中村聡", classIdChangeable: true, isNotifying: true))
        classList.append(ClassData(classId: 8317003, dayAndPeriod: 29, name: "生物3", room: "105教室", url: "https://ct.ritsumei.ac.jp/ct/course_8317003", professorName: "中村聡", classIdChangeable: true, isNotifying: true))
        classList.append(ClassData(classId: 8317004, dayAndPeriod: 31, name: "クリケット", room: "105教室", url: "https://ct.ritsumei.ac.jp/ct/course_8317004", professorName: "中村聡", classIdChangeable: true, isNotifying: true))
        classList.append(ClassData(classId: 8317005, dayAndPeriod: 32, name: "サーフィン", room: "105教室", url: "https://ct.ritsumei.ac.jp/ct/course_8317005", professorName: "中村聡", classIdChangeable: true, isNotifying: true))
        classList.append(ClassData(classId: 8317006, dayAndPeriod: 33, name: "水泳", room: "105教室", url: "https://ct.ritsumei.ac.jp/ct/course_8317006", professorName: "中村聡", classIdChangeable: true, isNotifying: true))
        classList.append(ClassData(classId: 8317007, dayAndPeriod: 35, name: "柔道", room: "105教室", url: "https://ct.ritsumei.ac.jp/ct/course_8317007", professorName: "中村聡", classIdChangeable: true, isNotifying: true))
        classList.append(ClassData(classId: 8317008, dayAndPeriod: 36, name: "空手", room: "105教室", url: "https://ct.ritsumei.ac.jp/ct/course_8317008", professorName: "中村聡", classIdChangeable: true, isNotifying: true))
        classList.append(ClassData(classId: 8317009, dayAndPeriod: 37, name: "合気道", room: "105教室", url: "https://ct.ritsumei.ac.jp/ct/course_8317009", professorName: "中村聡", classIdChangeable: true, isNotifying: true))
        classList.append(ClassData(classId: 8317010, dayAndPeriod: 38, name: "フェンシング", room: "105教室", url: "https://ct.ritsumei.ac.jp/ct/course_8317010", professorName: "中村聡", classIdChangeable: true, isNotifying: true))
        classList.append(ClassData(classId: 8317011, dayAndPeriod: 39, name: "ホッケー", room: "105教室", url: "https://ct.ritsumei.ac.jp/ct/course_8317011", professorName: "中村聡", classIdChangeable: true, isNotifying: true))
        classList.append(ClassData(classId: 8317012, dayAndPeriod: 40, name: "野球", room: "105教室", url: "https://ct.ritsumei.ac.jp/ct/course_8317012", professorName: "中村聡", classIdChangeable: true, isNotifying: true))
        
        // これを必要な数だけ繰り返し、適切なデータを追加します。
    }
    */
    func setupCurrentClassroomLabel() {
        currentClassroomLabel = UILabel()
        currentClassroomLabel.text = "現在の教室"
        currentClassroomLabel.backgroundColor = UIColor(red: 0.88, green: 1.0, blue: 0.88, alpha: 1.0)
        currentClassroomLabel.textAlignment = .center
        currentClassroomLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(currentClassroomLabel)
        
        NSLayoutConstraint.activate([
            currentClassroomLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            currentClassroomLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            currentClassroomLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            currentClassroomLabel.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    func setupShowNotificationsButton() {
        showNotificationsButton = UIButton(type: .system)
        showNotificationsButton.translatesAutoresizingMaskIntoConstraints = false
        showNotificationsButton.setTitle("+", for: .normal)
        showNotificationsButton.titleLabel?.font = UIFont.systemFont(ofSize: 30)
        showNotificationsButton.backgroundColor = .blue
        showNotificationsButton.tintColor = .white
        showNotificationsButton.layer.cornerRadius = 25
        showNotificationsButton.addTarget(self, action: #selector(showNotifications), for: .touchUpInside)
        self.view.addSubview(showNotificationsButton)
        
        NSLayoutConstraint.activate([
            showNotificationsButton.widthAnchor.constraint(equalToConstant: 50),
            showNotificationsButton.heightAnchor.constraint(equalToConstant: 50),
            showNotificationsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            showNotificationsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])
        self.view.bringSubviewToFront(showNotificationsButton)
    }
    
    @objc func showNotifications() {
        let notificationVC = NotificationViewController()
        notificationVC.modalPresentationStyle = .fullScreen
        self.present(notificationVC, animated: true, completion: nil)
    }
    
    func updateCurrentClassroomLabel() {
        let now = Date()
        let calendar = Calendar.current
        let dayOfWeek = (calendar.component(.weekday, from: now) - 1 + 6) % 7 // 0基準に調整（月曜が0）
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let totalMinutes = hour * 60 + minute
        
        let periods = [
            (start: 510, end: 610),  // 1限目
            (start: 610, end: 750),  // 2限目
            (start: 750, end: 850),  // 3限目
            (start: 850, end: 950),  // 4限目
            (start: 950, end: 1050), // 5限目
            (start: 1050, end: 1150),// 6限目
            (start: 1150, end: 1240) // 7限目
        ]
        
        // 授業時間外の場合
        if totalMinutes < periods[0].start || totalMinutes > periods.last!.end {
            currentClassroomLabel.text = "空きコマです"
            return
        }
        
        // 授業時間内で適切な授業を探す
        guard let periodIndex = periods.firstIndex(where: { totalMinutes >= $0.start && totalMinutes <= $0.end }) else {
            currentClassroomLabel.text = "空きコマです"
            return
        }
        print("dayOfWeek\(dayOfWeek)")
        print("periodIndex\(periodIndex)")
        let classIndex = dayOfWeek + periodIndex * 7
        print("hei")
        print(classIndex)
        let matchingClasses = classDataManager.classList.filter { $0.dayAndPeriod == classIndex }
        
        if let classInfo = matchingClasses.first {
            currentClassroomLabel.text = "\(classInfo.name) @ \(classInfo.room)"
        } else {
            currentClassroomLabel.text = "空きコマです"
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = taskDataManager.taskList[indexPath.row]
        
        // NotifyManagerにタスク通知を追加
        //NotifyManager.shared.addNotifications(for: task)
        
        // 通知ビューコントローラを表示
        let notificationVC = NotificationViewController()
        notificationVC.taskName = task.taskName
        notificationVC.dueDate = task.dueDate
        notificationVC.notificationTiming = task.notificationTiming ?? []
        notificationVC.taskId = task.taskId
        notificationVC.managedObjectContext = managedObjectContext // ここでmanagedObjectContextを渡す
        notificationVC.modalPresentationStyle = .custom
        notificationVC.transitioningDelegate = self
        present(notificationVC, animated: true, completion: nil)
    }
    func didPickDate(date: Date, forTaskId taskId: Int) {
        if let index = taskDataManager.taskList.firstIndex(where: { $0.taskId == taskId }) {
            taskDataManager.taskList[index].notificationTiming?.append(date)
            saveNotificationTiming(date, forTaskId: taskId)
            tableView.reloadData()
            
            // taskListの中身をプリントアウト
            print("Updated taskList:")
            printTaskList()
            
            // CoreDataの中身をプリントアウト
            print("Updated CoreData:")
            printCoreDataTaskData()
        }
    }
    // TODO: CoreDataとtaskListを一致させるためのメソッド作成。また、全ファイルでのtaskListの統一（これができたら、TaskDataManagerのloadTaskDataで事足りる）
    func saveNotificationTiming(_ date: Date, forTaskId taskId: Int) {
        print("通知日時の保存を行うよ")
        print(taskId)
        let fetchRequest: NSFetchRequest<TaskDataStore> = TaskDataStore.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "taskId == %lld", taskId)
        
        do {
            print("doを実行します")
            let tasks = try managedObjectContext.fetch(fetchRequest)
            print("Fetched tasks count: \(tasks.count)")
            if let task = tasks.first {
                print("ifを実行します")
                var timings = task.notificationTiming as? [Date] ?? []
                timings.append(date)
                task.notificationTiming = timings as NSArray
                
                try managedObjectContext.save()
                print("保存されたよー")
                // CoreDataの中身をプリントアウト
                print("CoreData after saving notification timing:")
                //printCoreDataTaskData()
            }
            // taskListの更新
            if let index = taskDataManager.taskList.firstIndex(where: { $0.taskId == taskId }) {
                var timings = taskDataManager.taskList[index].notificationTiming ?? []
                timings.append(date)
                taskDataManager.taskList[index].notificationTiming = timings
                print("taskListも更新されたよー")
                // taskListの中身をプリントアウト
                print("Updated taskList:")
                printTaskList()
            }
        } catch {
            print("Failed to update task with new notification timing: \(error)")
        }
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // データソースの項目数を返します（例：tasks.count）
        return taskDataManager.taskList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskTableViewCell", for: indexPath) as! TaskTableViewCell

        let task = taskDataManager.taskList[indexPath.row]
        cell.configure(with: task)

        return cell
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TaskTableViewCell.self, forCellReuseIdentifier: "TaskTableViewCell")
        
        // Auto Layoutを使用して配置
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 10), // collectionViewの下に配置
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor) // safe areaの下まで伸ばす
        ])
    }
    func updateCollectionViewHeight() {
        collectionView.layoutIfNeeded()
        collectionViewHeightConstraint?.constant = collectionView.contentSize.height
    }
   
    func updateActiveDaysAndMaxPeriod() {
        activeDays = ["月", "火", "水", "木", "金"] // 月曜から金曜まで常に含める
        maxPeriod = 0

        // 土日の授業の有無をチェックし、必要に応じて追加
        let weekend = ["土", "日"]
        var weekendClassesExist = [false, false]
        for classInfo in classDataManager.classList {
            print("ClassId: \(classInfo.classId), DayAndPeriod: \(classInfo.dayAndPeriod), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName), 変更可能な授業か: \(classInfo.classIdChangeable), 通知のオンオフ: \(classInfo.isNotifying)")
        }
        for classInfo in classDataManager.classList {
            let idInt = classInfo.dayAndPeriod
            let dayIndex = idInt % 7
            //print("dayIndex\(dayIndex)")
            let period = idInt / 7 + 1
            maxPeriod = max(maxPeriod, period)
            
            // 土日の授業があるかどうかをチェック
            if dayIndex >= 5 { // 土日の場合
                weekendClassesExist[dayIndex - 5] = true
                // 日曜日の授業が存在する場合、土曜日も表示させる
                if dayIndex == 6 { // 日曜日の場合
                    weekendClassesExist[0] = true // 土曜日も表示
                }
            }
        }
        
        // 土日の授業があればactiveDaysに追加
        for (index, exists) in weekendClassesExist.enumerated() where exists {
            activeDays.append(weekend[index])
        }
        
        // UICollectionViewのレイアウトを更新
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            // セルのサイズを計算
            //print("列数")
            //print(activeDays.count)
            let numberOfItemsPerRow: CGFloat = CGFloat(activeDays.count + 1)
            let spacingBetweenCells: CGFloat = 1
            let totalSpacing = (2 * layout.sectionInset.left) + ((numberOfItemsPerRow - 1) * spacingBetweenCells)
            let itemWidth = (collectionView.bounds.width - totalSpacing) / numberOfItemsPerRow
            layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
            
            // セクションインセットも必要に応じて更新
            layout.sectionInset = UIEdgeInsets(top: spacingBetweenCells, left: spacingBetweenCells, bottom: spacingBetweenCells, right: spacingBetweenCells)
            
            // レイアウトの更新をトリガー
            collectionView.collectionViewLayout.invalidateLayout()
        }
        collectionView.reloadData()
        //print("itemWidth: \(layout.itemSize.width), itemHeight: \(layout.itemSize.height)")
    }
    
    func classInfoDidUpdate(_ updatedClassInfo: ClassData) {
        print("受け取った更新された授業情報：")
        print("ClassId: \(updatedClassInfo.classId), DayAndPeriod: \(updatedClassInfo.dayAndPeriod), 名前: \(updatedClassInfo.name), 教室: \(updatedClassInfo.room), URL: \(updatedClassInfo.url), 教授名: \(updatedClassInfo.professorName), 通知のオンオフ: \(updatedClassInfo.isNotifying)")
        // 授業情報を更新
        if let index = classDataManager.classList.firstIndex(where: { $0.name == updatedClassInfo.name }) {
            classDataManager.classList[index] = updatedClassInfo
            print("classListを更新しました。")
        } else {
            print("更新する授業情報が見つかりませんでした。")
        }
        classDataManager.classList.sort { (classInfo1, classInfo2) -> Bool in
            return classInfo1.dayAndPeriod < classInfo2.dayAndPeriod
        }

        // 更新後のclassListの内容を確認
        print("更新後のclassListの内容確認：")
        classDataManager.classList.forEach { classInfo in
            print("ClassId: \(classInfo.classId), DayAndPeriod: \(classInfo.dayAndPeriod), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName), 通知のオンオフ: \(classInfo.isNotifying)")
        }
        classDataManager.replaceClassDataIntoDB(classInformationList: classDataManager.classList)
        // コレクションビューを更新
        self.updateActiveDaysAndMaxPeriod()
        updateCollectionViewHeight()
        setupTableView()
        setupCurrentClassroomLabel()
    }
    
    func showClassInfoPopup(for classInfo: ClassData) {
        let popupVC = ClassInfoPopupViewController()
        popupVC.classInfo = classInfo
        popupVC.delegate = self // ここでデリゲートを設定
        popupVC.modalPresentationStyle = .overCurrentContext
        popupVC.modalTransitionStyle = .crossDissolve
        present(popupVC, animated: true, completion: nil)
    }
    
    func addUnregisteredClass(time: String, location: String) {
        // 時間をIDに変換するロジック（仮実装）
        let id = convertTimeToId(time: time)

        // 未登録授業情報を取得（仮に最初のものを取得するとします）
        if let unregisteredClass = classesToRegister.first {
            let newClass = ClassData(classId: unregisteredClass.classId, dayAndPeriod: id, name: unregisteredClass.name, room: location, url: unregisteredClass.url, professorName: unregisteredClass.professorName, classIdChangeable: true, isNotifying: true)
            classDataManager.classList.append(newClass)
            classDataManager.replaceClassDataIntoDB(classInformationList: classDataManager.classList)
            // 使用した未登録授業情報をclassesToRegisterから削除
            classesToRegister.removeFirst()
        }
        classDataManager.classList.sort { (classInfo1, classInfo2) -> Bool in
            return classInfo1.dayAndPeriod < classInfo2.dayAndPeriod
        }

        print("クラスリストの内容確認（未登録追加後）:")
        for classInfo in classDataManager.classList {
            print("DayAndPeriod: \(classInfo.dayAndPeriod), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName)")
        }
        
        // コレクションビューを更新
        self.updateActiveDaysAndMaxPeriod()
        updateCollectionViewHeight()
        setupTableView()
        setupCurrentClassroomLabel()
    }
    
    func convertTimeToId(time: String) -> Int {
        // 曜日と時限のマッピング
        let dayToOffset: [String: Int] = ["月": 0, "火": 1, "水": 2, "木": 3, "金": 4, "土": 5, "日": 6]
        let periodToOffset: [Int] = [0, 7, 14, 21, 28, 35, 42]

        // 入力された時間から曜日と時限を抽出
        let dayIndex = dayToOffset[String(time.prefix(1))] ?? 0
        let periodIndex = Int(String(time.suffix(1))) ?? 1

        // IDを計算
        let id = periodToOffset[periodIndex - 1] + dayIndex
        return id
    }


    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = indexPath.item / (activeDays.count + 1)
        let column = indexPath.item % (activeDays.count + 1)
        self.updateActiveDaysAndMaxPeriod()
        // 一番左上のセルの場合、未登録授業の追加処理を行う（classesToRegisterにデータがある場合のみ）
        if indexPath.item == 0 {
            print("追加ボタン押された")
            // classesToRegisterにデータが存在する場合のみ未登録授業の追加処理を実施
            if !classesToRegister.isEmpty {
                // 未登録授業の追加処理
                presentUnregisteredClassAlert()
            } else {
                print("追加する未登録授業がありません。")
            }
            return
        }
        
        // その他のヘッダーセルを無視
        if row == 0 || column == 0 { return }
        
        // 授業セルの処理
        let dayIndex = column - 1
        let period = row
        let dayAndPeriod = dayIndex + (period - 1) * 7
        
        // 対応するClassInformationオブジェクトを取得してポップアップ表示
        if let classInfo = classDataManager.classList.first(where: { Int($0.dayAndPeriod) == dayAndPeriod }) {
            showClassInfoPopup(for: classInfo)
        }
    }

    // 未登録授業の追加処理を行う関数
    private func presentUnregisteredClassAlert() {
        let title = classesToRegister.first?.name ?? "未登録授業の追加"
        let alertController = UIAlertController(title: title, message: "時間（例：月2）と場所を入力してください", preferredStyle: .alert)

        // 時間のテキストフィールド
        alertController.addTextField { textField in
            textField.placeholder = "時間（例：月2）"
        }
        // 場所のテキストフィールド
        alertController.addTextField { textField in
            textField.placeholder = "場所"
        }

        let addAction = UIAlertAction(title: "追加", style: .default) { [weak self, unowned alertController] _ in
            let timeTextField = alertController.textFields?[0]
            let locationTextField = alertController.textFields?[1]

            // 入力された時間と場所を取得
            guard let time = timeTextField?.text, let location = locationTextField?.text else { return }

            // ここで未登録授業の追加処理を行う
            self?.addUnregisteredClass(time: time, location: location)
            //self?.classDataManager.replaceClassDataIntoDB(classInformationList: classDataManager.classList)
            self?.classDataManager.replaceClassDataIntoDB(classInformationList: self?.classDataManager.classList ?? [])
            self?.setupTableView()
        }

        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)

        alertController.addAction(addAction)
        alertController.addAction(cancelAction)

        // アラートを表示
        self.present(alertController, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //print("列の数\(activeDays.count)")
        //print("行の数\(maxPeriod)")
        return (activeDays.count + 1) * (maxPeriod + 1)
    }
  
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ClassCell", for: indexPath) as? ClassCollectionViewCell else {
            fatalError("The dequeued cell is not an instance of ClassCollectionViewCell.")
        }
        
        let row = indexPath.item / (activeDays.count + 1)
        let column = indexPath.item % (activeDays.count + 1)
        
        if row == 0 {
            let text = column == 0 ? "" : activeDays[column - 1]
            cell.configure(text: text)
            cell.backgroundColor = .lightGray
        } else if column == 0 {
            cell.configure(text: "\(row)")
            cell.backgroundColor = .lightGray
        } else {
            // 授業セルの設定（修正）
            let dayIndex = column - 1 // activeDaysのインデックス
            let period = row
            let classId = dayIndex + (period - 1) * 7 // ここでclassIdを計算
            
            if let classInfo = classDataManager.classList.first(where: { Int($0.dayAndPeriod) == classId }) {
                // 初期設定
                cell.configure(text: "")
                cell.backgroundColor = .green
                
                // classIdChangeableがtrueの場合は矢印記号を表示
                if classInfo.classIdChangeable {
                    cell.configure(text: "🔄")
                }
                
                // taskListに該当する未提出のタスクがあるかチェック
                let hasUnsubmittedTask = taskDataManager.taskList.contains(where: { $0.belongedClassName == classInfo.name && !$0.hasSubmitted })
                if hasUnsubmittedTask {
                    cell.backgroundColor = .red // 未提出のタスクがあれば赤に変更
                }
            } else {
                // 該当するclassInfoがない場合は背景色を白に
                cell.configure(text: "")
                cell.backgroundColor = .white
            }
        }
        return cell
    }
    /*
    @objc func clearUserDefaults() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        // 必要に応じてUIの更新や確認メッセージを表示
        print("UserDefaultsがクリアされました。")
    }
     */
    func assembleCookieString() -> String {
        // UserDefaultsから全データを取得
        let userDefaultsDictionary = UserDefaults.standard.dictionaryRepresentation()

        // クッキー文字列を組み立てるための変数
        var cookieParts: [String] = []

        // UserDefaultsから取得した全てのキーと値でループ
        for (key, value) in userDefaultsDictionary {
            // 値がString型の場合のみ組み立てる
            // 特定のプレフィックスを持つキーに絞り込むなど、条件を追加しても良いかもしれません
            if let valueString = value as? String {
                // クッキーの形式に従って組み立て
                cookieParts.append("\(key)=\(valueString)")
            }
        }

        // クッキーパーツをセミコロンで結合
        let cookieString = cookieParts.joined(separator: "; ")
        print("cookieStringここから")
        //print(cookieString)
        print("ここまで")
        return cookieString
    }

    
    func checkLoginStatus() {
        print("UserDefaultsの中身:")
        for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
            //print("\(key): \(value)")
        }
        if UserDefaults.standard.string(forKey: "sessionid") == nil {
            // ログイン特有のクッキーが含まれていない場合
            print("ログイン出来てなかった")
            presentLoginViewController()
        } else {
            print("ログイン出来てた")
            // ログイン特有のクッキーが存在する場合、ログインプロセスをスキップ
            // ログイン済みのユーザー用の処理をここに記述
        }
    }
    
    func presentLoginViewController() {
        guard self.presentedViewController == nil else {
            print("既に別のビューコントローラが表示されています。")
            return
        }
        print("LoginViewControllerを表示します。")
        let loginVC = LoginViewController()
        loginVC.modalPresentationStyle = .formSheet // または .pageSheet など
        self.present(loginVC, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear in SecondViewController")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("collectionView.frame: \(collectionView.frame)")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear in SecondViewController")
        print("チェック開始")
        checkLoginStatus()
        print("チェック完了")
    }
}
