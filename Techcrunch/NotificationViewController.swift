import UIKit
import CoreData
import UserNotifications

class NotificationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DatePickerViewControllerDelegate, UNUserNotificationCenterDelegate {
    
    var titleLabel: UILabel!
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
        setupTableView()
        setupSubmitButton()
        setupAddButton()
        
        self.view.backgroundColor = .white
        
        // UNUserNotificationCenterのデリゲートを設定
        UNUserNotificationCenter.current().delegate = self

        // タイトルラベルに課題名を設定
        //titleLabel.text = taskName
        
        // 受け取ったnotificationTimingを元に表示するデータを設定
        setupNotifications()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let formattedNotificationTimings = notificationTiming.map { dateFormatter.string(from: $0) }.joined(separator: ", ")
        print("NotificationViewController's Notification Timings: \(formattedNotificationTimings)")
        sortNotifications()
        tableView.reloadData()
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
        submitButton.setTitleColor(.black, for: .normal)
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
        
        let titleText = taskName
        let attributedText = NSAttributedString(string: titleText, attributes: [
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ])
        titleLabel.attributedText = attributedText
        
        self.view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    func setupTableView() {
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.view.addSubview(tableView)
        
        tableView.layer.borderColor = UIColor.black.cgColor
        tableView.layer.borderWidth = 1.0
        tableView.separatorColor = .black 
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.layoutMargins = UIEdgeInsets.zero
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
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
        addButton.backgroundColor = UIColor(red: 87.0/255.0, green: 162.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        addButton.tintColor = .white
        addButton.layer.cornerRadius = 25
        addButton.layer.borderWidth = 0.5 // 枠線の太さ
        addButton.layer.borderColor = UIColor.black.cgColor // 枠線の色
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)

        // ボタン内のコンテンツを中央に揃える
        addButton.contentHorizontalAlignment = .center
        addButton.contentVerticalAlignment = .center

        // タイトルの位置を少し上に移動
        addButton.titleEdgeInsets = UIEdgeInsets(top: -4, left: 1, bottom: 0, right: 0)

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
        notificationTiming.sort()
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
            sortNotifications()
            tableView.reloadData()
            
            // 通知のスケジュール
            let dueDateFormatter = DateFormatter()
            dueDateFormatter.dateStyle = .short
            dueDateFormatter.timeStyle = .short
            let dueDateString = dueDateFormatter.string(from: dueDate)
            print("今からこの通知を設定するよ: \(taskName)")
            scheduleNotification(at: date, title: taskName, subTitle: "Due date: \(dueDateString)", taskId: taskId)

            // CoreDataに保存
            saveNotificationTiming(date, forTaskId: taskId)
            printAllTaskDataStores()
        }
        // SecondViewControllerに通知タイミングを反映
        if let secondVC = self.presentingViewController as? SecondViewController {
            secondVC.didPickDate(date: date, forTaskId: taskId)
            print("実行されたよー")
        }
    }
    
    func sortNotifications() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        notifications.sort { (lhs, rhs) -> Bool in
            let lhsDate = dateFormatter.date(from: "\(lhs.date) \(lhs.time)") ?? Date.distantPast
            let rhsDate = dateFormatter.date(from: "\(rhs.date) \(rhs.time)") ?? Date.distantPast
            return lhsDate < rhsDate
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
        
        // アイコンの設定
        let clockAttachment = NSTextAttachment()
        clockAttachment.image = UIImage(named: "clock_icon") // アイコン画像を設定
        
        // アイコンのサイズ調整
        let iconHeight = cell.textLabel?.font.lineHeight ?? 17.0 // フォントのラインハイトに合わせる
        let iconRatio = clockAttachment.image!.size.width / clockAttachment.image!.size.height
        clockAttachment.bounds = CGRect(x: 0, y: (cell.textLabel?.font.capHeight ?? 17.0 - iconHeight) / 2 - 2, width: iconHeight * iconRatio, height: iconHeight)
        
        // アイコンをNSAttributedStringに変換
        let clockString = NSAttributedString(attachment: clockAttachment)
        
        // テキストの設定
        let notificationText = " \(notification.date) \(notification.time)"
        let notificationAttributedString = NSMutableAttributedString(string: notificationText)
        
        // アイコンをテキストの先頭に追加
        notificationAttributedString.insert(clockString, at: 0)
        
        // セルのテキストラベルに設定
        cell.textLabel?.attributedText = notificationAttributedString
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { (action, view, completionHandler) in
            // 削除する通知の日時を取得
            let notificationToDelete = self.notificationTiming[indexPath.row]
            print("削除する通知の日時: \(notificationToDelete)")
            
            // 通知の削除
            self.notificationTiming.remove(at: indexPath.row)
            self.notifications.remove(at: indexPath.row)
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
                secondVC.removeNotificationTiming(notificationToDelete, forTaskId: self.taskId)
            }
            
            // CoreDataから該当の通知タイミングを削除
            self.removeNotificationTimingFromCoreData(notificationToDelete, forTaskId: self.taskId)
            
            // notificationTimingをソートする
            self.notificationTiming.sort()
            // notificationsもソートする
            self.sortNotifications()
            
            completionHandler(true)
        }
        
        // ゴミ箱のアイコンを設定
        deleteAction.image = UIImage(systemName: "trash")
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        
        return configuration
    }
    
    // ヘッダーのビューを設定
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .white
        
        let headerLabel = UILabel()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.font = UIFont.systemFont(ofSize: 18)
        headerLabel.textAlignment = .center
        headerLabel.text = "通知時刻一覧"
        
        headerView.addSubview(headerLabel)
        
        NSLayoutConstraint.activate([
            headerLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            headerLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    // ヘッダーの高さを設定
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25
    }
    
    func printNotifications() {
        print("現在の通知一覧:")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for notification in notifications {
            print("通知日時: \(notification.date) \(notification.time)")
        }
    }
    
    // プリントする関数の実装
    func printAllTaskDataStores() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        print("今のタスクのCoreDataの中身")
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<TaskDataStore> = TaskDataStore.fetchRequest()
        
        do {
            let tasks = try context.fetch(fetchRequest)
            for task in tasks {
                print("Task ID: \(task.taskId)")
                print("Task Name: \(task.taskName ?? "N/A")")
                print("Belong Class Name: \(task.belongClassName ?? "N/A")")
                if let dueDate = task.dueDate {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .short
                    formatter.timeStyle = .short
                    print("Due Date: \(formatter.string(from: dueDate))")
                } else {
                    print("Due Date: N/A")
                }
                print("Has Submitted: \(task.hasSubmitted)")
                if let notificationTiming = task.notificationTiming as? [Date] {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .short
                    formatter.timeStyle = .short
                    let notificationTimingStrings = notificationTiming.map { formatter.string(from: $0) }
                    print("Notification Timing: \(notificationTimingStrings.joined(separator: ", "))")
                } else {
                    print("Notification Timing: N/A")
                }
                print("Task URL: \(task.taskURL ?? "N/A")")
                print("----------")
            }
        } catch {
            print("Failed to fetch tasks: \(error)")
        }
    }

}
