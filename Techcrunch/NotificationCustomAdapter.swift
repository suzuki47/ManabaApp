//
//  DetailViewController.swift
//  Techcrunch
//
//  Created by 鈴木悠太 on 2023/08/01.
//
import UIKit
import UserNotifications
import CoreData
/*
protocol NotificationCustomAdapterDelegate: AnyObject {
    func didUpdateNotificationDates(for taskName: String, _ dates: [Date])
}
/* 2/8
class NotificationCustomAdapter: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var notificationDialog: NotificationCustomDialog?
    let addNotificationDialog = AddNotificationDialog()
    
    weak var delegate: NotificationCustomAdapterDelegate?
    var taskName: String = ""
    var taskDetail: String = ""
    var notificationDates: [Date] = [] // 通知のタイミングを保存
    
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
        
        // AddNotificationDialogのviewControllerプロパティを設定
        addNotificationDialog.viewController = self
        
        let notificationDialog = NotificationCustomDialog(notificationDates: notificationDates, taskName: taskName, delegate: self, adapter: self)
        tableView.delegate = notificationDialog
        // 通知の日付をCoreDataから取得
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
        // tableViewの設定
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: notificationCellIdentifier)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: notificationCellIdentifier, for: indexPath)
        cell.textLabel?.text = dateFormatter.string(from: notificationDates[indexPath.row])
        return cell
    }
    //セルをタップした時
    /*func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     let selectedDate = notificationDates[indexPath.row]
     addNotificationDialog.presentDatePickerAlert(title: "通知の日時を編集", selectedDate: selectedDate, completion: { [weak self] updatedDate in
     self?.notificationDates[indexPath.row] = updatedDate
     self?.tableView.reloadData()
     self?.updateTaskDataStore()
     })
     tableView.deselectRow(at: indexPath, animated: true)
     }
     //セルの削除
     func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     notificationDates.remove(at: indexPath.row)
     delegate?.didUpdateNotificationDates(for: taskName, notificationDates)
     tableView.deleteRows(at: [indexPath], with: .fade)
     }
     }*/
    
    // MARK: - CoreData Operations
    private func fetchNotificationDatesFromCoreData() {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else { return }
        let fetchRequest = NSFetchRequest<DataStore>(entityName: "DataStore")
        fetchRequest.predicate = NSPredicate(format: "name == %@", taskName)
        
        do {
            if let taskDataStore = try context.fetch(fetchRequest).first {
                notificationDates = taskDataStore.notificationTiming as? [Date] ?? []
            }
        } catch {
            print("Failed to fetch notification dates from CoreData: \(error)")
        }
    }
    
    func updateDataStore() {
        _ = NotificationCustomAdapter.saveOrUpdateDataStore(with: taskName, detail: taskDetail, dueDate: nil, notificationDates: notificationDates)
    }
    
    // MARK: - UI Alert Management
    /*private func presentDatePickerAlert(title: String, selectedDate: Date, completion: @escaping (Date) -> Void) {
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
     }*/
    //通知の追加
    @IBAction func addNotificationDate() {
        addNotificationDialog.presentDatePickerAlert(title: "通知の日時を選択", selectedDate: Date()) { [weak self] selectedDate in
            self?.notificationDates.append(selectedDate)
            self?.tableView.reloadData()
            self?.updateDataStore()
        }
    }
    
    // MARK: - Static CoreData Operations
    static func saveOrUpdateDataStore(with name: String, detail: String, dueDate: Date?, notificationDates: [Date]) -> DataStore {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else { fatalError("Could not fetch the context.") }
        let fetchRequest = NSFetchRequest<DataStore>(entityName: "DataStore")
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        let datastore: DataStore
        if let existingTask = try? context.fetch(fetchRequest).first {
            datastore = existingTask
        } else {
            datastore = NSEntityDescription.insertNewObject(forEntityName: "DataStore", into: context) as! DataStore
        }
        
        datastore.title = name
        datastore.detail = detail
        if let dueDate = dueDate {
            //datastore.subtitle = dueDate
        }
        datastore.notificationTiming = notificationDates as NSArray
        //datastore.isNotified = true
        
        do {
            try context.save()
        } catch {
            print("Failed to save or update datastore: \(error)")
        }
        
        return datastore
    }
}
extension NotificationCustomAdapter: NotificationCustomAdapterDelegate {
    func didUpdateNotificationDates(for taskName: String, _ dates: [Date]) {
        // ここに通知日付が更新された際の処理を追加します。
        // 例えば、データベースの更新やUIのリフレッシュなどが考えられます。
        // 今回は、notificationDatesの更新とtableViewのリロードを行います。
        self.notificationDates = dates
        self.tableView.reloadData()
    }
}
*/
*/
