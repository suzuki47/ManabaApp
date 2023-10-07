//
//  DetailViewController.swift
//  Techcrunch
//
//  Created by 鈴木悠太 on 2023/08/01.
//
/*
 import UIKit
 import UserNotifications
 import CoreData
 
 
 protocol DetailViewControllerDelegate: AnyObject {
 func didUpdateNotificationDates(for taskName: String, _ dates: [Date])
 }
 class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
 weak var delegate: DetailViewControllerDelegate?
 var taskName: String = ""
 var taskDetail: String = ""
 var notificationDates: [Date] = [] // 通知のタイミングを保存
 
 @IBOutlet weak var detailTextView: UITextView!
 @IBOutlet weak var tableView: UITableView!
 
 override func viewDidLoad() {
 super.viewDidLoad()
 //通知の許可
 let center = UNUserNotificationCenter.current()
 center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
 if granted {
 print("Notifications permission granted.")
 } else {
 print("Notifications permission denied because: \(error?.localizedDescription ?? "Unknown error").")
 }
 }
 
 print("Task Detail: \(taskDetail)")
 print("Task Name: \(taskName)")
 
 print("Notification Dates: \(notificationDates)")
 print("DetailViewController viewDidLoad called")
 print("Number of notificationDates: \(notificationDates.count)")
 // 通知の日付をCoreDataから取得
 fetchNotificationDatesFromCoreData()
 // tableViewの設定
 tableView.delegate = self
 tableView.dataSource = self
 tableView.register(UITableViewCell.self, forCellReuseIdentifier: "notificationCell")
 
 detailTextView.text = taskDetail
 
 tableView.reloadData()
 }
 
 // MARK: - TableView DataSource and Delegate
 override func viewWillDisappear(_ animated: Bool) {
 super.viewWillDisappear(animated)
 delegate?.didUpdateNotificationDates(for: taskName, notificationDates)
 }
 //テーブルビューのセル数
 func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
 return notificationDates.count
 }
 //各セルの内容設定
 func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
 print("tableView(_:cellForRowAt:) called for row: \(indexPath.row)")
 let cell = tableView.dequeueReusableCell(withIdentifier: "notificationCell", for: indexPath)
 
 let notificationDate = notificationDates[indexPath.row]
 let dateFormatter = DateFormatter()
 dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
 
 cell.textLabel?.text = dateFormatter.string(from: notificationDate)
 
 return cell
 }
 //セルをタップした時
 func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
 let selectedDate = notificationDates[indexPath.row]
 
 let alert = UIAlertController(title: "通知の日時を編集", message: "\n\n\n\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
 let datePicker = UIDatePicker()
 datePicker.datePickerMode = .dateAndTime
 datePicker.preferredDatePickerStyle = .wheels
 datePicker.date = selectedDate
 datePicker.frame = CGRect(x: 17, y: 52, width: 250, height: 162)
 alert.view.addSubview(datePicker)
 
 let okAction = UIAlertAction(title: "更新", style: .default) { [weak self] _ in
 let updatedDate = datePicker.date
 self?.notificationDates[indexPath.row] = updatedDate
 self?.delegate?.didUpdateNotificationDates(for: self?.taskName ?? "", self?.notificationDates ?? [])
 
 self?.tableView.reloadData()
 _ = DetailViewController.saveOrUpdateTaskDataStore(with: self?.taskName ?? "", detail: self?.taskDetail ?? "", dueDate: nil, notificationDates: self?.notificationDates ?? [])
 
 }
 
 let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
 
 alert.addAction(okAction)
 alert.addAction(cancelAction)
 
 present(alert, animated: true, completion: nil)
 
 tableView.deselectRow(at: indexPath, animated: true)
 }
 // CoreDataから通知の日付を取得する
 func fetchNotificationDatesFromCoreData() {
 let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
 let fetchRequest = NSFetchRequest<TaskDataStore>(entityName: "TaskDataStore")
 fetchRequest.predicate = NSPredicate(format: "name == %@", taskName)
 
 do {
 if let taskDataStore = try context.fetch(fetchRequest).first {
 // CoreData から取得した通知日付をプロパティに設定
 notificationDates = taskDataStore.notificationDates as? [Date] ?? []
 }
 } catch {
 print("Failed to fetch notification dates from CoreData: \(error)")
 }
 }
 //通知の追加
 @IBAction func addNotificationDate() {
 let alert = UIAlertController(title: "通知の日時を選択", message: "\n\n\n\n\n\n\n\n", preferredStyle: .alert)
 
 let datePicker = UIDatePicker()
 datePicker.datePickerMode = .dateAndTime
 datePicker.frame = CGRect(x: 15, y: 50, width: 250, height: 120)
 alert.view.addSubview(datePicker)
 
 let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
 let selectedDate = datePicker.date
 self?.notificationDates.append(selectedDate)
 self?.delegate?.didUpdateNotificationDates(for: self?.taskName ?? "", self?.notificationDates ?? [])
 
 self?.scheduleNotification(for: selectedDate, with: UUID().uuidString, taskName: self?.taskName ?? "タスク")
 self?.tableView.reloadData()
 _ = DetailViewController.saveOrUpdateTaskDataStore(with: self?.taskName ?? "", detail: self?.taskDetail ?? "", dueDate: nil, notificationDates: self?.notificationDates ?? [])
 let savedTaskDataStore = DetailViewController.saveOrUpdateTaskDataStore(with: self?.taskName ?? "", detail: self?.taskDetail ?? "", dueDate: nil, notificationDates: self?.notificationDates ?? [])
 /*if let self = self {
  let updatedTaskData = self.convertToTaskData(from: savedTaskDataStore)
  let dates = updatedTaskData.notificationDates
  self.delegate?.didUpdateNotificationDates(for: updatedTaskData.name, dates)
  }*/
 
 
 
 
 
 
 
 // TODO: ここでupdatedTaskDataをテーブルビューのデータソースに追加または更新
 }
 
 let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
 
 alert.addAction(okAction)
 alert.addAction(cancelAction)
 
 present(alert, animated: true, completion: nil)
 }
 // TaskDataStoreからTaskDataへの変換
 func convertToTaskData(from store: TaskDataStore) -> TaskData {
 let name = store.name ?? ""
 let dueDate = store.dueDate ?? Date()
 let detail = store.detail ?? ""
 let taskType = Int(store.taskType)
 var taskData = TaskData(name: name, dueDate: dueDate, detail: detail, taskType: taskType)
 if let notificationDates = store.notificationDates as? [Date] {
 notificationDates.forEach { taskData.addNotificationDate($0) }
 }
 return taskData
 }
 //通知のスケジュール
 func scheduleNotification(for date: Date, with identifier: String, taskName: String) {
 let center = UNUserNotificationCenter.current()
 
 let content = UNMutableNotificationContent()
 content.title = "\(taskName)の通知"  // タスク名をタイトルに含めます
 content.body = "\(taskName)の期限が近づいています！"
 content.sound = .default
 
 let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
 let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
 
 let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
 center.add(request) { error in
 if let error = error {
 print("Error: \(error)")
 }
 }
 }
 private static var persistentContainer: NSPersistentCloudKitContainer! = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
 // TaskDataStoreの保存または更新
 static func saveOrUpdateTaskDataStore(with name: String, detail: String, dueDate: Date?, notificationDates: [Date]) -> TaskDataStore {
 let context = persistentContainer.viewContext
 
 // 既存のTaskDataStoreを検索します。
 let fetchRequest = NSFetchRequest<TaskDataStore>(entityName: "TaskDataStore")
 fetchRequest.predicate = NSPredicate(format: "name == %@", name)
 
 let taskdatastore: TaskDataStore
 if let existingTask = try? context.fetch(fetchRequest).first {
 taskdatastore = existingTask
 } else {
 taskdatastore = NSEntityDescription.insertNewObject(forEntityName: "TaskDataStore", into: context) as! TaskDataStore
 }
 
 taskdatastore.name = name
 taskdatastore.detail = detail
 if let dueDate = dueDate {
 taskdatastore.dueDate = dueDate
 }
 // 通知日時を保存するための変換や方法が必要です。ここでは単純に最初の日時を保存します。
 taskdatastore.notificationDates = notificationDates as NSObject
 taskdatastore.isNotified = true
 
 do {
 try context.save()
 } catch {
 print("Failed to save or update taskdatastore: \(error)")
 }
 
 return taskdatastore
 }
 //セルの削除
 func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
 if editingStyle == .delete {
 notificationDates.remove(at: indexPath.row)
 delegate?.didUpdateNotificationDates(for: taskName, notificationDates)
 tableView.deleteRows(at: [indexPath], with: .fade)
 }
 }
 
 }
 */
import UIKit
import UserNotifications
import CoreData

protocol DetailViewControllerDelegate: AnyObject {
    func didUpdateNotificationDates(for taskName: String, _ dates: [Date])
}

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    weak var delegate: DetailViewControllerDelegate?
    var taskName: String = ""
    var taskDetail: String = ""
    var notificationDates: [Date] = []
    
    @IBOutlet weak var detailTextView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    
    private let notificationCellIdentifier = "notificationCell"
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestNotificationPermission()
        fetchNotificationDatesFromCoreData()
        configureTableView()
        detailTextView.text = taskDetail
    }
    
    // MARK: - Notification Permission
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print(granted ? "Notifications permission granted." : "Notifications permission denied because: \(error?.localizedDescription ?? "Unknown error").")
        }
    }
    
    // MARK: - TableView Configuration
    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: notificationCellIdentifier)
    }
    
    // MARK: - TableView DataSource and Delegate
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.didUpdateNotificationDates(for: taskName, notificationDates)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notificationDates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: notificationCellIdentifier, for: indexPath)
        cell.textLabel?.text = dateFormatter.string(from: notificationDates[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedDate = notificationDates[indexPath.row]
        presentDatePickerAlert(title: "通知の日時を編集", selectedDate: selectedDate, completion: { [weak self] updatedDate in
            self?.notificationDates[indexPath.row] = updatedDate
            self?.tableView.reloadData()
            self?.updateTaskDataStore()
        })
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            notificationDates.remove(at: indexPath.row)
            delegate?.didUpdateNotificationDates(for: taskName, notificationDates)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // MARK: - CoreData Operations
    private func fetchNotificationDatesFromCoreData() {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else { return }
        let fetchRequest = NSFetchRequest<TaskDataStore>(entityName: "TaskDataStore")
        fetchRequest.predicate = NSPredicate(format: "name == %@", taskName)
        
        do {
            if let taskDataStore = try context.fetch(fetchRequest).first {
                notificationDates = taskDataStore.notificationDates as? [Date] ?? []
            }
        } catch {
            print("Failed to fetch notification dates from CoreData: \(error)")
        }
    }
    
    private func updateTaskDataStore() {
        _ = DetailViewController.saveOrUpdateTaskDataStore(with: taskName, detail: taskDetail, dueDate: nil, notificationDates: notificationDates)
    }
    
    // MARK: - UI Alert Management
    private func presentDatePickerAlert(title: String, selectedDate: Date, completion: @escaping (Date) -> Void) {
        let alert = UIAlertController(title: title, message: "\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.frame = CGRect(x: 15, y: 50, width: 250, height: 120)
        datePicker.date = selectedDate
        alert.view.addSubview(datePicker)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak datePicker] _ in
            if let selectedDate = datePicker?.date {
                completion(selectedDate)
            }
        }
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func addNotificationDate() {
        presentDatePickerAlert(title: "通知の日時を選択", selectedDate: Date()) { [weak self] selectedDate in
            self?.notificationDates.append(selectedDate)
            self?.tableView.reloadData()
            self?.updateTaskDataStore()
        }
    }
    
    // MARK: - Static CoreData Operations
    static func saveOrUpdateTaskDataStore(with name: String, detail: String, dueDate: Date?, notificationDates: [Date]) -> TaskDataStore {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else { fatalError("Could not fetch the context.") }
        let fetchRequest = NSFetchRequest<TaskDataStore>(entityName: "TaskDataStore")
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        let taskdatastore: TaskDataStore
        if let existingTask = try? context.fetch(fetchRequest).first {
            taskdatastore = existingTask
        } else {
            taskdatastore = NSEntityDescription.insertNewObject(forEntityName: "TaskDataStore", into: context) as! TaskDataStore
        }
        
        taskdatastore.name = name
        taskdatastore.detail = detail
        if let dueDate = dueDate {
            taskdatastore.dueDate = dueDate
        }
        taskdatastore.notificationDates = notificationDates as NSObject
        taskdatastore.isNotified = true
        
        do {
            try context.save()
        } catch {
            print("Failed to save or update taskdatastore: \(error)")
        }
        
        return taskdatastore
    }
}

