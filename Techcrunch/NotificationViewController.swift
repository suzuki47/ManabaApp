import UIKit
import CoreData
import UserNotifications

class NotificationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DatePickerViewControllerDelegate, UNUserNotificationCenterDelegate {
    
    var titleLabel: UILabel!
    var subtitleLabel: UILabel!
    var tableView: UITableView!
    var addButton: UIButton!
    var submitButton: UIButton!
    
    // 追加: 通知タイミングの配列
    var notificationTiming: [Date] = []
    
    var notifications: [(date: String, time: String)] = []
    
    // 追加: 課題名と期限日時のプロパティ
    var taskName: String = ""
    var dueDate: Date = Date()
    var taskId: Int = 0
    var taskURL: String = ""
    var managedObjectContext: NSManagedObjectContext! // ここでmanagedObjectContextを追加
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTitleLabel()
        setupSubtitleLabel()
        setupTableView()
        setupSubmitButton()
        setupAddButton()
        
        self.view.backgroundColor = .white
        
        // UNUserNotificationCenterのデリゲートを設定
        UNUserNotificationCenter.current().delegate = self

        // タイトルラベルに課題名を設定
        titleLabel.text = taskName
        
        // 受け取ったnotificationTimingを元に表示するデータを設定
        setupNotifications()
    }
    
    @objc private func openURL() {
        let baseURLString = "https://ct.ritsumei.ac.jp/ct/"
        let urlString = baseURLString + taskURL
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        } else {
            print("URLが無効です: \(urlString)")
        }
    }
    
    func setupSubmitButton() {
        submitButton = UIButton(type: .system)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.setTitle("課題を提出する→", for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        submitButton.addTarget(self, action: #selector(openURL), for: .touchUpInside)
        self.view.addSubview(submitButton)
        
        NSLayoutConstraint.activate([
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    // 通知の受信時に呼ばれるメソッド
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        handleReceivedNotification(notification: notification)
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        handleReceivedNotification(notification: response.notification)
        completionHandler()
    }
    
    func handleReceivedNotification(notification: UNNotification) {
        let identifierComponents = notification.request.identifier.components(separatedBy: "_")
        guard identifierComponents.count > 1 else {
            print("通知のIDからtaskIdを取得できませんでした。")
            return
        }
        
        let taskIdString = identifierComponents[1]
        
        // String から Int に変換
        guard let taskId = Int(taskIdString) else {
            print("taskId '\(taskIdString)' を Int に変換できませんでした。")
            return
        }
        
        guard let trigger = notification.request.trigger as? UNCalendarNotificationTrigger,
              let notificationDate = Calendar.current.date(from: trigger.dateComponents) else {
            print("通知のトリガーから日時を取得できませんでした。")
            return
        }
        
        // SecondViewControllerのtaskListから該当の通知タイミングを削除
        if let secondVC = self.presentingViewController as? SecondViewController {
            secondVC.removeNotificationTiming(notificationDate, forTaskId: taskId)
        }
        
        // CoreDataから該当の通知タイミングを削除
        removeNotificationTimingFromCoreData(notificationDate, forTaskId: taskId)
        
        // NotificationViewControllerの通知タイミングとnotificationsから該当の通知タイミングを削除
        if let index = notificationTiming.firstIndex(of: notificationDate) {
            notificationTiming.remove(at: index)
            notifications.remove(at: index)
            tableView.reloadData()
            print("NotificationViewController: 通知タイミングが削除されました。")
        }
    }


    func removeNotificationTimingFromCoreData(_ date: Date, forTaskId taskId: Int) {
        let fetchRequest: NSFetchRequest<TaskDataStore> = TaskDataStore.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "taskId == %lld", taskId)
        
        do {
            let tasks = try managedObjectContext.fetch(fetchRequest)
            if let task = tasks.first {
                var timings = task.notificationTiming as? [Date] ?? []
                
                // 通知タイミングの削除
                if let index = timings.firstIndex(of: date) {
                    timings.remove(at: index)
                    task.notificationTiming = timings as NSArray
                }
                
                // 変更を保存
                try managedObjectContext.save()
                print("CoreData: 通知タイミングが削除されました。")
                print("削除後のCoreDataの内容: \(task.notificationTiming ?? [])")
            } else {
                print("タスクID: \(taskId) のタスクが見つかりません")
            }
        } catch {
            print("Failed to delete notification timing from CoreData: \(error)")
        }
    }

    
    func setupNavigationBar() {
        let navigationBar = UINavigationBar()
        let navigationItem = UINavigationItem(title: "通知設定")
        
        let cancelButton = UIBarButtonItem(title: "キャンセル", style: .plain, target: self, action: #selector(cancelButtonTapped))
        navigationItem.leftBarButtonItem = cancelButton
        
        navigationBar.items = [navigationItem]
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationBar)
        
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func setupTitleLabel() {
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        self.view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    func setupSubtitleLabel() {
        subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "通知時刻一覧"
        subtitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        subtitleLabel.textAlignment = .center
        self.view.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    func setupTableView() {
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100)
        ])
    }
    
    func setupAddButton() {
        addButton = UIButton(type: .system)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("+", for: .normal)
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 30)
        addButton.backgroundColor = .green
        addButton.tintColor = .white
        addButton.layer.cornerRadius = 25
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        self.view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.widthAnchor.constraint(equalToConstant: 50),
            addButton.heightAnchor.constraint(equalToConstant: 50),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            addButton.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -20) // submitButtonの上に配置
        ])
        
        // ボタンを一番前に持ってくる
        self.view.bringSubviewToFront(addButton)
    }
    
    func setupNotifications() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        notifications = notificationTiming.map { date in
            let dateString = dateFormatter.string(from: date)
            let components = dateString.split(separator: " ")
            if components.count == 2 {
                return (date: String(components[0]), time: String(components[1]))
            }
            return (date: "", time: "")
        }
        
        tableView.reloadData()
    }
    
    @objc func addButtonTapped() {
        let datePickerVC = DatePickerViewController()
        datePickerVC.delegate = self
        datePickerVC.taskId = self.taskId
        datePickerVC.modalPresentationStyle = .fullScreen
        present(datePickerVC, animated: true, completion: nil)
    }
    
    @objc func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    func didPickDate(date: Date, forTaskId taskId: Int) {
        notificationTiming.append(date)
        print("NotificationViewController: didPickDateが呼び出されました。受け取った日時: \(date), タスクID: \(taskId)")
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: date)
        let components = dateString.split(separator: " ")
        if components.count == 2 {
            let dateString = String(components[0])
            let timeString = String(components[1])
            notifications.append((date: dateString, time: timeString))
            tableView.reloadData()
            
            // 通知のスケジュール
            let dueDateFormatter = DateFormatter()
            dueDateFormatter.dateStyle = .short
            dueDateFormatter.timeStyle = .short
            let dueDateString = dueDateFormatter.string(from: dueDate)
            print("今からこの通知を設定するよ: \(taskName)")
            scheduleNotification(at: date, title: taskName, subTitle: "Due date: \(dueDateString)", taskId: taskId)

            // CoreDataに保存
            //saveNotificationTiming(date, forTaskId: taskId)
        }
        // SecondViewControllerに通知タイミングを反映
        if let secondVC = self.presentingViewController as? SecondViewController {
            secondVC.didPickDate(date: date, forTaskId: taskId)
            print("実行されたよー")
        }
    }
    
    func saveNotificationTiming(_ date: Date, forTaskId taskId: Int) {
        let fetchRequest: NSFetchRequest<TaskDataStore> = TaskDataStore.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "taskId == %d", taskId)
        
        do {
            let tasks = try managedObjectContext.fetch(fetchRequest)
            if let task = tasks.first {
                var timings = task.notificationTiming as? [Date] ?? []
                timings.append(date)
                task.notificationTiming = timings as NSArray
                
                try managedObjectContext.save()
                print("保存されたよー")
            }
        } catch {
            print("Failed to update task with new notification timing: \(error)")
        }
    }
    
    func scheduleNotification(at date: Date, title: String, subTitle: String, taskId: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = subTitle
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = "task_\(taskId)_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            }
        }
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let notification = notifications[indexPath.row]
        cell.textLabel?.text = "\(notification.date) \(notification.time)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 削除する通知の日時を取得
            let notificationToDelete = notificationTiming[indexPath.row]
            print("削除する通知の日時: \(notificationToDelete)")
            
            // 通知の削除
            notificationTiming.remove(at: indexPath.row)
            notifications.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            print("NotificationViewController: 通知が削除されました。")
            print("削除後の通知一覧")
            let center = UNUserNotificationCenter.current()
            center.getPendingNotificationRequests { requests in
                for request in requests {
                    let content = request.content
                    let trigger = request.trigger as? UNCalendarNotificationTrigger
                    let triggerDate = trigger?.nextTriggerDate()
                    
                    print("Notification ID: \(request.identifier)")
                    print("Title: \(content.title)")
                    print("Body: \(content.body)")
                    print("Next Trigger Date: \(String(describing: triggerDate))")
                }
            }
            
            // SecondViewControllerのtaskListから該当の通知タイミングを削除
            if let secondVC = self.presentingViewController as? SecondViewController {
                secondVC.removeNotificationTiming(notificationToDelete, forTaskId: taskId)
            }
            
            // CoreDataから該当の通知タイミングを削除
            removeNotificationTimingFromCoreData(notificationToDelete, forTaskId: taskId)
        }
    }

    func printNotifications() {
        print("現在の通知一覧:")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for notification in notifications {
            print("通知日時: \(notification.date) \(notification.time)")
        }
    }

}
