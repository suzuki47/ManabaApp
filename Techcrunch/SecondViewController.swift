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

class SecondViewController: UIViewController, UITableViewDelegate, WKNavigationDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource, ClassInfoPopupDelegate, UIViewControllerTransitioningDelegate, DatePickerViewControllerDelegate, UnregisteredClassesPopupDelegate {
    var collectionView: UICollectionView!
    var currentClassroomLabel: UILabel!
    var flashingButton: UIButton!
    var showNotificationsButton: UIButton!
    var managedObjectContext: NSManagedObjectContext!
    var taskListLabel: UILabel!
    var context: NSManagedObjectContext!
    var cookies: [HTTPCookie]?
    var activeDays: [String] = []
    var maxPeriod = 0
    var collectionViewHeightConstraint: NSLayoutConstraint?
    var tableView: UITableView!
    var classDataManager: ClassDataManager!
    var taskDataManager: TaskDataManager!
    var sectionedTasks: [TaskSection: [TaskData]] = [:]
    
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
        collectionView.backgroundColor = UIColor.black
        
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
        
        taskDataManager = TaskDataManager(dataName: "TaskData", context: context)
        classDataManager = ClassDataManager(dataName: "ClassData", context: context)
        Task {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm" // 日付のフォーマットを設定
            classDataManager.loadClassData()
            taskDataManager.deletePastDueTasks(context: context)
            self.updateActiveDaysAndMaxPeriod()
            await taskDataManager.loadTaskData()
            //実験ここから
            await taskDataManager.getTaskDataFromManaba()
            // ここから実験のためのサンプル追加（のちに削除）
            let date1 = dateFormatter.date(from: "2024/09/17 23:00")!
            let date2 = dateFormatter.date(from: "2024/09/18 23:00")!
            let date3 = dateFormatter.date(from: "2024/09/19 23:00")!

            // taskListのサンプルデータ
            var sampleTaskList: [TaskData] = [
                TaskData(taskName: "SampleTask 1", dueDate: date1, belongedClassName: "31765:サンプルA", taskURL: "url1", hasSubmitted: false, notificationTiming: nil, taskId: 1111111),
                TaskData(taskName: "SampleTask 2", dueDate: date2, belongedClassName: "31765:サンプルB", taskURL: "url2", hasSubmitted: false, notificationTiming: nil, taskId: 2222222),
                TaskData(taskName: "SampleTask 3", dueDate: date3, belongedClassName: "31765:サンプルC", taskURL: "url3", hasSubmitted: false, notificationTiming: nil, taskId: 3333333)
            ]
            
            taskDataManager.taskList.append(contentsOf: sampleTaskList)
            print("1111111111111111111111111111111")
            print("allTaskDataListの内容確認（SecondViewController）:")
            for classInfo in taskDataManager.allTaskDataList {
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
            print("allTaskDataListの内容確認（SecondViewController）ここまで")
            print("----------------------------------------------------")
            print("taskListの内容確認（SecondViewController）:")
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
            print("taskListの内容確認（SecondViewController）ここまで")
            print("1111111111111111111111111111111")
            // サンプル追加はここまで
            // taskListに存在しないもののhasSubmittedをtrueにする
            let taskListIds = Set(taskDataManager.taskList.map { $0.taskId })

            for task in taskDataManager.allTaskDataList {
                if !taskListIds.contains(task.taskId) {
                    task.hasSubmitted = true
                }
            }
            
            // taskListに存在するtaskIdのデータがあったら、allTaskDataListのそのデータのtaskName、dueDateをtaskListのものに更新
            let taskListDict = Dictionary(uniqueKeysWithValues: taskDataManager.taskList.map { ($0.taskId, $0) })

            for task in taskDataManager.allTaskDataList {
                if let updatedTask = taskListDict[task.taskId] {
                    task.taskName = updatedTask.taskName
                    task.dueDate = updatedTask.dueDate
                }
            }
            
            // taskListに存在するtaskIdのデータがなかったら、allTaskDataListにそのデータを追加
            let allTaskIds = Set(taskDataManager.allTaskDataList.map { $0.taskId })

            for task in taskDataManager.taskList {
                if !allTaskIds.contains(task.taskId) {
                    taskDataManager.allTaskDataList.append(task)
                }
            }
            
            //重複しているnotificationTimingを削除した後に、その順にソートする
            for index in taskDataManager.allTaskDataList.indices {
                if let timings = taskDataManager.allTaskDataList[index].notificationTiming {
                    // 重複する日時を削除
                    let uniqueTimings = Array(Set(timings))
                    // 日時順にソート
                        taskDataManager.taskList[index].notificationTiming = uniqueTimings.sorted()
                }
            }
            
            taskDataManager.allTaskDataList = taskDataManager.allTaskDataList.sorted { $0.dueDate < $1.dueDate }
            print("2222222222222222222222222222222222222")
            print("allTaskDataListの内容確認（SecondViewController）:")
            for classInfo in taskDataManager.allTaskDataList {
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
            print("allTaskDataListの内容確認（SecondViewController）ここまで")
            print("----------------------------------------------------")
            print("taskListの内容確認（SecondViewController）:")
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
            print("taskListの内容確認（SecondViewController）ここまで")
            print("2222222222222222222222222222222222222")
            //実験ここまで
            //重複しているnotificationTimingを削除した後に、その順にソートする
            for index in taskDataManager.allTaskDataList.indices {
                if let timings = taskDataManager.allTaskDataList[index].notificationTiming {
                    // 重複する日時を削除
                    let uniqueTimings = Array(Set(timings))
                    // 日時順にソート
                        taskDataManager.taskList[index].notificationTiming = uniqueTimings.sorted()
                }
            }
            taskDataManager.insertTaskDataIntoDB(taskList: taskDataManager.allTaskDataList)
            
            print("ロード後のクラスリストの内容確認（SecondViewController）:")
            for classInfo in classDataManager.classList {
                print("ClassId: \(classInfo.classId), DayAndPeriod: \(classInfo.dayAndPeriod), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName), 変更可能な授業か: \(classInfo.classIdChangeable), 通知のオンオフ: \(classInfo.isNotifying)")
            }
            
            for classData in classDataManager.classList {
                if !classData.isNotifying {
                    let newStatus = ClassIdAndIsNotifying(classId: classData.classId, isNotifying: classData.isNotifying)
                    classDataManager.notificationStatus.append(newStatus)
                }
            }
            classDataManager.keptClasses = classDataManager.classList.filter { $0.classIdChangeable }.map { $0.copy() }
            print("classDataManager.keptClassesの内容確認（SecondViewController）:")
            for classInfo in classDataManager.keptClasses {
                print("ClassId: \(classInfo.classId), DayAndPeriod: \(classInfo.dayAndPeriod), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName), 変更可能な授業か: \(classInfo.classIdChangeable), 通知のオンオフ: \(classInfo.isNotifying)")
            }
            
            classDataManager.classList = classDataManager.classList.filter { $0.classIdChangeable }
            
            print("classIdChangeable=false削除後のクラスリストの内容確認（SecondViewController）:")
            for classInfo in classDataManager.classList {
                print("ClassId: \(classInfo.classId), DayAndPeriod: \(classInfo.dayAndPeriod), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName), 変更可能な授業か: \(classInfo.classIdChangeable), 通知のオンオフ: \(classInfo.isNotifying)")
            }
            await classDataManager.getChangeableClassDataFromManaba()
            print("unregisteredClassListの内容確認（SecondViewController）:")
            for classInfo in classDataManager.unregisteredClassList {
                print("ClassId: \(classInfo.classId),  授業名:\(classInfo.name),  URL: \(classInfo.url), 教授名: \(classInfo.professorName)")
            }
            for unregisteredClass in classDataManager.unregisteredClassList {
                if !classDataManager.classList.contains(where: { $0.classId == unregisteredClass.classId }) {
                    let newClassData = ClassData(
                        classId: unregisteredClass.classId,
                        dayAndPeriod: 49, // 空の値
                        name: unregisteredClass.name,
                        room: "", // 空の値
                        url: unregisteredClass.url,
                        professorName: unregisteredClass.professorName,
                        classIdChangeable: true, // true に設定
                        isNotifying: true // true に設定
                    )
                    classDataManager.classesToRegister.append(newClassData)
                }
            }
            print("classesToRegisterの内容確認（SecondViewController）:")
            for classInfo in classDataManager.classesToRegister {
                print("ClassId: \(classInfo.classId), DayAndPeriod: \(classInfo.dayAndPeriod), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName), 変更可能な授業か: \(classInfo.classIdChangeable), 通知のオンオフ: \(classInfo.isNotifying)")
            }
        
            await classDataManager.getUnChangeableClassDataFromManaba()
            await classDataManager.getProfessorNameFromManaba()
            print("classDataManager.keptClassesの内容確認（SecondViewController）:")
            for classInfo in classDataManager.keptClasses {
                print("ClassId: \(classInfo.classId), DayAndPeriod: \(classInfo.dayAndPeriod), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName), 変更可能な授業か: \(classInfo.classIdChangeable), 通知のオンオフ: \(classInfo.isNotifying)")
            }
            // 保管していた授業をclassListに追加
            classDataManager.classList.append(contentsOf: classDataManager.keptClasses)
            
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
            
            classDataManager.replaceClassDataIntoDB(classInformationList: classDataManager.classList)
            print("クラスリストの内容確認（SecondViewController）:")
            for classInfo in classDataManager.classList {
                print("ID: \(classInfo.dayAndPeriod), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName), 変更可能な授業か:\(classInfo.classIdChangeable)")
            }
            
            print("最終タスクリストの内容確認（SecondViewController）:")
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm" // 日付のフォーマットを設定
            
            for classInfo in taskDataManager.allTaskDataList {
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
            sectionedTasks = classifyTasks(tasks: taskDataManager.allTaskDataList)

            print("classDataManager.classesToRegisterの授業:\(classDataManager.classesToRegister)")
            self.updateActiveDaysAndMaxPeriod()
            updateCollectionViewHeight()
            setupTaskListLabel()
            setupTableView()
            print("未登録授業追加ボタンを設置します")
            setupFlashingButton()
            
            print("通知直前のクラスリストの内容確認（SecondViewController）:")
            for classInfo in classDataManager.classList {
                print("ClassId: \(classInfo.classId), DayAndPeriod: \(classInfo.dayAndPeriod), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName), 変更可能な授業か: \(classInfo.classIdChangeable), 通知のオンオフ: \(classInfo.isNotifying)")
            }
            
            // クラスリストを処理して通知を追加
            for classInfo in classDataManager.classList {
                NotifyManager.shared.addClassNotifications(for: classInfo)
            }
           
            // タスクリストの通知を追加
            for task in taskDataManager.allTaskDataList {
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
        //DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
        //    self.resetCoreData()
        //}
        print("Finished viewDidLoad in SecondViewController")
    }
    func setupFlashingButton() {
        flashingButton = UIButton(type: .system)
        flashingButton.setTitle("！", for: .normal)
        flashingButton.setTitleColor(.white, for: .normal)
        flashingButton.backgroundColor = .black
        flashingButton.layer.cornerRadius = 15
        flashingButton.translatesAutoresizingMaskIntoConstraints = false
        flashingButton.addTarget(self, action: #selector(flashingButtonTapped), for: .touchUpInside)
        
        view.addSubview(flashingButton)
        
        NSLayoutConstraint.activate([
            flashingButton.widthAnchor.constraint(equalToConstant: 30),
            flashingButton.heightAnchor.constraint(equalToConstant: 30),
            flashingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            flashingButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
        
        if !classDataManager.classesToRegister.isEmpty {
            startFlashing(button: flashingButton)
        } else {
            stopFlashing(button: flashingButton)
        }
    }
    
    @objc func flashingButtonTapped() {
        showUnregisteredClassesPopup()
    }
    
    func startFlashing(button: UIButton) {
        let flash = CABasicAnimation(keyPath: "opacity")
        flash.fromValue = 1.0
        flash.toValue = 0.0
        flash.duration = 0.5
        flash.autoreverses = true
        flash.repeatCount = .greatestFiniteMagnitude
        button.layer.add(flash, forKey: "flashAnimation")
    }
    
    func stopFlashing(button: UIButton) {
        button.layer.removeAnimation(forKey: "flashAnimation")
    }
    
    func showUnregisteredClassesPopup() {
        let popupVC = UnregisteredClassesPopupViewController()
        popupVC.classesToRegister = classDataManager.classesToRegister
        popupVC.delegate = self
        popupVC.modalPresentationStyle = .popover
        popupVC.preferredContentSize = CGSize(width: 300, height: 400)
        
        if let popoverController = popupVC.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
            popoverController.delegate = self
        }
        
        present(popupVC, animated: true, completion: nil)
    }
    
    // UnregisteredClassesPopupDelegate の実装
    func didSelectClass(_ classInfo: ClassData, from controller: UnregisteredClassesPopupViewController) {
        controller.dismiss(animated: true) {
            self.showClassInfoPopup(for: classInfo)
        }
    }
    
    func removeNotificationTiming(_ date: Date, forTaskId taskId: Int) {
        if let index = taskDataManager.allTaskDataList.firstIndex(where: { $0.taskId == taskId }) {
            var timings = taskDataManager.allTaskDataList[index].notificationTiming ?? []
            
            // 通知タイミングの削除
            if let timingIndex = timings.firstIndex(of: date) {
                timings.remove(at: timingIndex)
                taskDataManager.allTaskDataList[index].notificationTiming = timings
                print("SecondViewController: allTaskDataListから通知タイミングが削除されました。")
            } else {
                print("SecondViewController: 通知タイミングが見つかりませんでした。")
            }
            
            // taskListの中身をプリントアウト
            print("Updated allTaskDataList after deletion:")
            printTaskList()
        } else {
            print("SecondViewController: タスクID: \(taskId) のタスクが見つかりませんでした。")
        }
    }

    func resetCoreData() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "MyClassDataStore")
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
        
        for task in taskDataManager.allTaskDataList {
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

    func setupCurrentClassroomLabel() {
        currentClassroomLabel = UILabel()
        currentClassroomLabel.text = "空きコマです"
        currentClassroomLabel.backgroundColor = UIColor(red: 219.0/255.0, green: 246.0/255.0, blue: 189.0/255.0, alpha: 1.0)
        currentClassroomLabel.textAlignment = .center
        currentClassroomLabel.font = UIFont.systemFont(ofSize: 24)
        currentClassroomLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(currentClassroomLabel)
        
        NSLayoutConstraint.activate([
            currentClassroomLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            currentClassroomLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            currentClassroomLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            currentClassroomLabel.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    func setupTaskListLabel() {
        taskListLabel = UILabel()
        taskListLabel.text = "課題一覧"
        taskListLabel.backgroundColor = UIColor(red: 87.0/255.0, green: 162.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        taskListLabel.textAlignment = .center
        currentClassroomLabel.font = UIFont.systemFont(ofSize: 20)
        taskListLabel.translatesAutoresizingMaskIntoConstraints = false
        taskListLabel.font = UIFont.boldSystemFont(ofSize: 17) // フォントを太字に設定
        taskListLabel.textColor = .white
        
        view.addSubview(taskListLabel)

        NSLayoutConstraint.activate([
            taskListLabel.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 0),
            taskListLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            taskListLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            taskListLabel.heightAnchor.constraint(equalToConstant: 50)
        ])
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
            let shortenedClassName = String(classInfo.name.dropFirst(6))
            let shortenedClassRoomName = String(classInfo.room.dropFirst(3))
            //currentClassroomLabel.text = "\(shortenedClassName) @ \(shortenedClassRoomName)"
            currentClassroomLabel.text = "次は\(shortenedClassRoomName)です"
        } else {
            currentClassroomLabel.text = "空きコマです"
        }
    }
    //taskDataManager.allTaskDataListをSecondViewControllerで実行せずに、NotificationViewControllerで実行する
    func didPickDate(date: Date, forTaskId taskId: Int) {
        if let index = taskDataManager.allTaskDataList.firstIndex(where: { $0.taskId == taskId }) {
            taskDataManager.allTaskDataList[index].notificationTiming?.append(date)
            //saveNotificationTiming(date, forTaskId: taskId)
            tableView.reloadData()
            
            // taskListの中身をプリントアウト
            print("Updated allTaskDataList:")
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
            if let index = taskDataManager.allTaskDataList.firstIndex(where: { $0.taskId == taskId }) {
                var timings = taskDataManager.allTaskDataList[index].notificationTiming ?? []
                timings.append(date)
                taskDataManager.allTaskDataList[index].notificationTiming = timings
                print("taskListも更新されたよー")
                // taskListの中身をプリントアウト
                print("Updated taskList:")
                printTaskList()
            }
        } catch {
            print("Failed to update task with new notification timing: \(error)")
        }
    }
    
    func classifyTasks(tasks: [TaskData]) -> [TaskSection: [TaskData]] {
        var classifiedTasks: [TaskSection: [TaskData]] = [.submitted: [], .today: [], .tomorrow: [], .later: []]
        let now = Date()
        let calendar = Calendar.current
        
        for task in tasks {
            if task.hasSubmitted {
                classifiedTasks[.submitted]?.append(task)
            } else {
                let startOfToday = calendar.startOfDay(for: now)
                let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
                let startOfDayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: startOfToday)!
                
                if calendar.isDateInToday(task.dueDate) {
                    classifiedTasks[.today]?.append(task)
                } else if calendar.isDate(task.dueDate, inSameDayAs: startOfTomorrow) {
                    classifiedTasks[.tomorrow]?.append(task)
                } else if task.dueDate >= startOfDayAfterTomorrow {
                    classifiedTasks[.later]?.append(task)
                }
            }
        }
        
        return classifiedTasks
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        if let taskSection = TaskSection(rawValue: section) {
            switch taskSection {
            case .submitted:
                headerView.backgroundColor = UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1.0) // 灰色がかった色
            default:
                headerView.backgroundColor = UIColor(red: 219.0/255.0, green: 246.0/255.0, blue: 189.0/255.0, alpha: 1.0)
            }
        }

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = .black

        if let taskSection = TaskSection(rawValue: section) {
            titleLabel.text = taskSection.title
        }
        //headerView.separatorInset = UIEdgeInsets.zero
        //headerView.layoutMargins = UIEdgeInsets.zero
        headerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -10),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return TaskSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return TaskSection(rawValue: section)?.title
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let taskSection = TaskSection(rawValue: section) else { return 0 }
        return sectionedTasks[taskSection]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskTableViewCell", for: indexPath) as! TaskTableViewCell
        
        guard let taskSection = TaskSection(rawValue: indexPath.section),
              let task = sectionedTasks[taskSection]?[indexPath.row] else {
            return cell
        }
        
        //cell.configure(with: task)
        cell.configure(with: task, inSection: taskSection)
        
        // セルのスタイルを変更
        switch taskSection {
        case .submitted:
            cell.contentView.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0) // 灰色がかった色
            cell.titleLabel.textColor = .darkGray
            cell.deadlineLabel.textColor = .darkGray
            cell.countdownLabel.textColor = .darkGray
        default:
            cell.contentView.backgroundColor = .white
            cell.titleLabel.textColor = .black
            cell.deadlineLabel.textColor = .gray
            cell.countdownLabel.textColor = .red
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let taskSection = TaskSection(rawValue: indexPath.section),
              let task = sectionedTasks[taskSection]?[indexPath.row] else {
            return
        }
        
        // NotifyManagerにタスク通知を追加
        // NotifyManager.shared.addNotifications(for: task)
        
        // デバッグプリント
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let formattedNotificationTimings = task.notificationTiming?.map { dateFormatter.string(from: $0) }.joined(separator: ", ") ?? "N/A"
        print("Selected Task's Notification Timings: \(formattedNotificationTimings)")
        print("Selected Task ID: \(task.taskId)")
        print("Selected Task Name: \(task.taskName)")
        
        // 通知ビューコントローラを表示
        let notificationVC = NotificationViewController()
        notificationVC.taskName = task.taskName
        notificationVC.dueDate = task.dueDate
        notificationVC.notificationTiming = task.notificationTiming ?? []
        notificationVC.taskId = task.taskId
        notificationVC.taskURL = task.taskURL
        notificationVC.managedObjectContext = managedObjectContext // ここでmanagedObjectContextを渡す
        notificationVC.modalPresentationStyle = .overCurrentContext
        notificationVC.transitioningDelegate = self
        
        let formattedVCNotificationTimings = notificationVC.notificationTiming.map { dateFormatter.string(from: $0) }.joined(separator: ", ")
        print("Notification Timings before presenting: \(formattedVCNotificationTimings)")
        
        self.present(notificationVC, animated: true, completion: nil)
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorColor = .black
        //tableView.separatorInset = UIEdgeInsets.zero
        //tableView.layoutMargins = UIEdgeInsets.zero
        
        //セクション間の隙間を埋める
        if #available(iOS 15, *) {
            tableView.sectionHeaderTopPadding = 0.01
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TaskTableViewCell.self, forCellReuseIdentifier: "TaskTableViewCell")
        
        //tableView.layer.borderColor = UIColor.black.cgColor
        //tableView.layer.borderWidth = 1.0
        
        // Auto Layoutを使用して配置
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: taskListLabel.bottomAnchor, constant: 0), // taskListLabelの下に配置
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
        /*
        for classInfo in classDataManager.classList {
            print("ClassId: \(classInfo.classId), DayAndPeriod: \(classInfo.dayAndPeriod), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName), 変更可能な授業か: \(classInfo.classIdChangeable), 通知のオンオフ: \(classInfo.isNotifying)")
        }
         */
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
            //layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
            let itemHeight = itemWidth * 0.6 // 幅の60%の高さに設定して長方形にする

            layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
            
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
        /*
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
        classDataManager.replaceClassDataIntoDB(classInformationList: classDataManager.classList)*/
        print("コレクションビューを更新します")
        // コレクションビューを更新
        self.updateActiveDaysAndMaxPeriod()
        updateCollectionViewHeight()
        setupTableView()
        setupCurrentClassroomLabel()
        setupFlashingButton()
    }
    
    func classInfoPopupDidClose() {
        self.updateActiveDaysAndMaxPeriod()
        self.updateCollectionViewHeight()
    }
    
    func showClassInfoPopup(for classInfo: ClassData) {
        let popupVC = ClassInfoPopupViewController()
        popupVC.classInfo = classInfo
        popupVC.classDataManager = self.classDataManager // ここで classDataManager を設定
        popupVC.delegate = self // ここでデリゲートを設定
        popupVC.modalPresentationStyle = .overCurrentContext
        popupVC.modalTransitionStyle = .crossDissolve
        present(popupVC, animated: true, completion: nil)
    }
    
    func showUnChangeableClassInfoPopup(for classInfo: ClassData) {
        let popupVC = UnChangeableClassInfoPopupViewController()
        popupVC.classInfo = classInfo
        popupVC.classDataManager = self.classDataManager // ここで classDataManager を設定
        popupVC.delegate = self // ここでデリゲートを設定
        popupVC.modalPresentationStyle = .overCurrentContext
        popupVC.modalTransitionStyle = .crossDissolve
        present(popupVC, animated: true, completion: nil)
    }
    
    func addUnregisteredClass(time: String, location: String) {
        // 時間をIDに変換するロジック（仮実装）
        let id = convertTimeToId(time: time)

        // 未登録授業情報を取得（仮に最初のものを取得するとします）
        if let unregisteredClass = classDataManager.classesToRegister.first {
            let newClass = ClassData(classId: unregisteredClass.classId, dayAndPeriod: id, name: unregisteredClass.name, room: location, url: unregisteredClass.url, professorName: unregisteredClass.professorName, classIdChangeable: true, isNotifying: true)
            classDataManager.classList.append(newClass)
            classDataManager.replaceClassDataIntoDB(classInformationList: classDataManager.classList)
            // 使用した未登録授業情報をclassesToRegisterから削除
            classDataManager.classesToRegister.removeFirst()
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
            /*
            // classesToRegisterにデータが存在する場合のみ未登録授業の追加処理を実施
            if !classDataManager.classesToRegister.isEmpty {
                // 未登録授業の追加処理
                presentUnregisteredClassAlert()
            } else {
                print("追加する未登録授業がありません。")
            }
             */
            return
        }
        
        // その他のヘッダーセルを無視
        if row == 0 || column == 0 { return }
        
        // 授業セルの処理
        let dayIndex = column - 1
        let period = row
        let dayAndPeriod = dayIndex + (period - 1) * 7
        /*
        // 対応するClassInformationオブジェクトを取得してポップアップ表示
        if let classInfo = classDataManager.classList.first(where: { Int($0.dayAndPeriod) == dayAndPeriod }) {
            showClassInfoPopup(for: classInfo)
        }
         */
        if let classInfo = classDataManager.classList.first(where: { Int($0.dayAndPeriod) == dayAndPeriod }) {
            if classInfo.classIdChangeable {
                showClassInfoPopup(for: classInfo)
            } else {
                showUnChangeableClassInfoPopup(for: classInfo)
            }
        }
    }

    // 未登録授業の追加処理を行う関数
    private func presentUnregisteredClassAlert() {
        let title = classDataManager.classesToRegister.first?.name ?? "未登録授業の追加"
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
            cell.backgroundColor = UIColor(red: 200/255.0, green: 200/255.0, blue: 200/255.0, alpha: 1.0)
        } else if column == 0 {
            cell.configure(text: "\(row)")
            cell.backgroundColor = UIColor(red: 200/255.0, green: 200/255.0, blue: 200/255.0, alpha: 1.0)
        } else {
            // 授業セルの設定（修正）
            let dayIndex = column - 1 // activeDaysのインデックス
            let period = row
            let classId = dayIndex + (period - 1) * 7 // ここでclassIdを計算
            
            if let classInfo = classDataManager.classList.first(where: { Int($0.dayAndPeriod) == classId }) {
                // 初期設定
                cell.configure(text: "")
                cell.backgroundColor = UIColor(red: 219.0/255.0, green: 246.0/255.0, blue: 189.0/255.0, alpha: 1.0)
                
                // classIdChangeableがtrueの場合はアイコンを表示
                if classInfo.classIdChangeable {
                    // アイコンの設定
                    let reloadAttachment = NSTextAttachment()
                    reloadAttachment.image = UIImage(named: "changeable_icon") // アイコン画像を設定
                    
                    // アイコンのサイズ調整
                    let iconHeight = cell.label.font.lineHeight * 1.5 // フォントのラインハイトに合わせる
                    let iconRatio = reloadAttachment.image!.size.width / reloadAttachment.image!.size.height
                    reloadAttachment.bounds = CGRect(x: 0, y: (cell.label.font.capHeight - iconHeight) / 2, width: iconHeight * iconRatio, height: iconHeight)
                    
                    // アイコンをNSAttributedStringに変換
                    let reloadString = NSAttributedString(attachment: reloadAttachment)
                    
                    // テキストの設定
                    let cellText = NSMutableAttributedString(string: "")
                    cellText.append(reloadString)
                    cellText.append(NSAttributedString(string: " "))
                    
                    // セルのテキストラベルに設定
                    cell.configure(attributedText: cellText)
                }
                
                // allTaskDataListに該当する未提出のタスクがあるかチェック
                let hasUnsubmittedTask = taskDataManager.allTaskDataList.contains(where: { $0.belongedClassName == classInfo.name && !$0.hasSubmitted })
                if hasUnsubmittedTask {
                    cell.backgroundColor = UIColor(red: 248.0/255.0, green: 143.0/255.0, blue: 111.0/255.0, alpha: 1.0) // 未提出のタスクがあれば赤に変更
                }
            } else {
                // 該当するclassInfoがない場合は背景色を白に
                cell.configure(text: "")
                cell.backgroundColor = .white
            }
        }
        return cell
    }
   
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
    // アラートを表示する関数
    func showLoginAlert() {
        let alert = UIAlertController(title: "ログインエラー", message: "ログインできていないのでリロードしてください", preferredStyle: .alert)
        
        let reloadAction = UIAlertAction(title: "リロード", style: .default) { _ in
            // リロードのロジックをここに実装
            self.reloadContent()
        }
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        
        alert.addAction(reloadAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // コンテンツをリロードする関数（ダミーの例）
    func reloadContent() {
        // リロードのロジックをここに実装
        print("リロード中...")
    }
    
    func checkLoginStatus() {
        print("UserDefaultsの中身:")
        for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
            //print("\(key): \(value)")
        }
        if UserDefaults.standard.string(forKey: "sessionid") == nil {
            // ログイン特有のクッキーが含まれていない場合
            print("ログイン出来てなかった")
            //showLoginAlert()
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
extension SecondViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
