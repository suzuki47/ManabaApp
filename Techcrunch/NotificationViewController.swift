import UIKit
import CoreData
import UserNotifications

class NotificationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DatePickerViewControllerDelegate, UNUserNotificationCenterDelegate {
    
    var contentView: UIView!
    
    var isEditingMode: Bool = false
    var selectedNotifications: Set<Int> = []
    
    var titleLabel: UILabel!
    var tableView: UITableView!
    var addButton: UIButton!
    var submitButton: UIButton!
    var cancelButton: UIButton!
    var deleteButton: UIButton!
    
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
        // 背景を半透明の黒色に設定
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // contentViewを作成
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor.white
        contentView.layer.cornerRadius = 10.0 // 角を丸める場合
        self.view.addSubview(contentView)
        
        // contentViewが画面の90％を占めるように制約を設定
        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            contentView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8),
            contentView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.8)
        ])
        
        //setupNavigationBar()
        setupTitleLabel()
        setupTableView()
        setupSubmitButton()
        setupAddButton()
        setupCancelButton()
        setupDeleteButton()
        
        // ボタンを非表示にする
        cancelButton.isHidden = true
        deleteButton.isHidden = true
        
        //self.view.backgroundColor = .white
        
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:)))
        tapGesture.delegate = self // UIGestureRecognizerDelegateに準拠する必要があります
        self.view.addGestureRecognizer(tapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        tableView.addGestureRecognizer(longPressGesture)
    }
    
    @objc func checkboxTapped(_ sender: UIButton) {
        let index = sender.tag
        if selectedNotifications.contains(index) {
            selectedNotifications.remove(index)
        } else {
            selectedNotifications.insert(index)
        }
        
        // セルのチェックボックスの画像を更新
        if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? NotificationCell {
            if selectedNotifications.contains(index) {
                cell.checkbox.setImage(UIImage(systemName: "checkmark.square"), for: .normal)
            } else {
                cell.checkbox.setImage(UIImage(systemName: "square"), for: .normal)
            }
        }
    }
    
    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let point = gestureRecognizer.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: point) {
                enterEditingMode()
            }
        }
    }
    
    @objc func deleteSelectedNotifications() {
        // インデックスを降順にソートして削除
        let indices = selectedNotifications.sorted(by: >)
        for index in indices {
            let notificationToDelete = notificationTiming[index]
            
            print("一括削除する通知の日時: \(notificationToDelete)")

            // データソースから削除
            notificationTiming.remove(at: index)
            notifications.remove(at: index)

            // CoreDataから削除
            removeNotificationTimingFromCoreData(notificationToDelete, forTaskId: self.taskId)
            
            // SecondViewControllerのtaskListから該当の通知タイミングを削除
            if let secondVC = self.presentingViewController as? SecondViewController {
                secondVC.removeNotificationTiming(notificationToDelete, forTaskId: self.taskId)
            }

            // スケジュールされた通知をキャンセル
            cancelScheduledNotification(at: notificationToDelete)
        }

        selectedNotifications.removeAll()

        // テーブルビューを更新
        tableView.reloadData()
        print("選択された通知が削除されました。")
    }
    
    func cancelScheduledNotification(at date: Date) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            for request in requests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let triggerDate = Calendar.current.date(from: trigger.dateComponents),
                   triggerDate == date {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
                    break
                }
            }
        }
    }
    
    @objc func cancelEditingMode() {
        isEditingMode = false
        selectedNotifications.removeAll()
        cancelButton.isHidden = true
        deleteButton.isHidden = true
        addButton.isHidden = false
        submitButton.isHidden = false

        // テーブルビューを更新
        tableView.reloadData()
    }
    
    func enterEditingMode() {
        isEditingMode = true
        selectedNotifications.removeAll()
        cancelButton.isHidden = false
        deleteButton.isHidden = false
        addButton.isHidden = true
        submitButton.isHidden = true

        // テーブルビューを更新してチェックボックスを表示
        tableView.reloadData()
    }
    
    func setupCancelButton() {
        cancelButton = UIButton(type: .system)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("キャンセル", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        cancelButton.setTitleColor(.black, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelEditingMode), for: .touchUpInside)
        contentView.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cancelButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20)
        ])
    }
    
    func setupDeleteButton() {
        deleteButton = UIButton(type: .system)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setTitle("一括削除", for: .normal)
        deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        deleteButton.setTitleColor(.red, for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteSelectedNotifications), for: .touchUpInside)
        contentView.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20)
        ])
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
        contentView.addSubview(submitButton)
        
        NSLayoutConstraint.activate([
            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            submitButton.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -20)
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
        contentView.addSubview(navigationBar)
        
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
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
        
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
    func setupTableView() {
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(NotificationCell.self, forCellReuseIdentifier: "cell")
        contentView.addSubview(tableView)
        
        tableView.layer.borderColor = UIColor.black.cgColor
        tableView.layer.borderWidth = 1.0
        tableView.separatorColor = .black 
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.layoutMargins = UIEdgeInsets.zero
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -100)
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

        contentView.addSubview(addButton)

        NSLayoutConstraint.activate([
            addButton.widthAnchor.constraint(equalToConstant: 50),
            addButton.heightAnchor.constraint(equalToConstant: 50),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            addButton.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -57) // submitButtonの上に配置
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! NotificationCell
        let notification = notifications[indexPath.row]
        
        // アイコンの設定
        let clockAttachment = NSTextAttachment()
        clockAttachment.image = UIImage(named: "clock_icon") // アイコン画像を設定
        
        // アイコンのサイズ調整
        let iconHeight = cell.titleLabel.font.lineHeight // フォントのラインハイトに合わせる
        let iconRatio = clockAttachment.image!.size.width / clockAttachment.image!.size.height
        clockAttachment.bounds = CGRect(x: 0, y: (cell.titleLabel.font.capHeight - iconHeight) / 2 - 2, width: iconHeight * iconRatio, height: iconHeight)
        
        // アイコンの垂直位置を少し下に調整
        let iconYOffset: CGFloat = -4.0 // 調整値。これを微調整してアイコンの高さを合わせる
        clockAttachment.bounds = CGRect(x: 0, y: iconYOffset, width: iconHeight * iconRatio, height: iconHeight)
        
        // アイコンをNSAttributedStringに変換
        let clockString = NSAttributedString(attachment: clockAttachment)
        
        // テキストの設定
        let notificationText = "    \(notification.date)    \(notification.time)"
        let notificationAttributedString = NSMutableAttributedString(string: notificationText)
        
        // アイコンをテキストの先頭に追加
        notificationAttributedString.insert(clockString, at: 0)
        
        // 正規表現で四桁の年（YYYY/）を削除
        let pattern = "\\d{4}/"
        if let rangeOfYear = notificationAttributedString.string.range(of: pattern, options: .regularExpression) {
            let nsRange = NSRange(rangeOfYear, in: notificationAttributedString.string)
            notificationAttributedString.deleteCharacters(in: nsRange)
        }
        
        // 「,」を削除
        if let commaRange = notificationAttributedString.string.range(of: ","), !commaRange.isEmpty {
            let nsRange = NSRange(commaRange, in: notificationAttributedString.string)
            notificationAttributedString.deleteCharacters(in: nsRange)
        }
        
        // セルのtitleLabelに設定
        cell.titleLabel.attributedText = notificationAttributedString

        // 編集モードの処理
        if isEditingMode {
            cell.checkbox.isHidden = false
            let notificationIndex = indexPath.row
            if selectedNotifications.contains(notificationIndex) {
                cell.checkbox.setImage(UIImage(systemName: "checkmark.square"), for: .normal)
            } else {
                cell.checkbox.setImage(UIImage(systemName: "square"), for: .normal)
            }
            
            // チェックボックスにターゲットを設定
            cell.checkbox.tag = indexPath.row
            cell.checkbox.addTarget(self, action: #selector(checkboxTapped(_:)), for: .touchUpInside)
        } else {
            cell.checkbox.isHidden = true
            cell.checkbox.removeTarget(self, action: #selector(checkboxTapped(_:)), for: .touchUpInside)
        }
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isEditingMode {
            // チェックボックスの状態を切り替える
            let index = indexPath.row
            if selectedNotifications.contains(index) {
                selectedNotifications.remove(index)
            } else {
                selectedNotifications.insert(index)
            }

            // セルのチェックボックスの画像を更新
            if let cell = tableView.cellForRow(at: indexPath) as? NotificationCell {
                if selectedNotifications.contains(index) {
                    cell.checkbox.setImage(UIImage(systemName: "checkmark.square"), for: .normal)
                } else {
                    cell.checkbox.setImage(UIImage(systemName: "square"), for: .normal)
                }
            }
        } else {
            // 通常のセル選択時の動作（必要であれば）
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
    @objc func backgroundTapped(_ sender: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }

}
extension NotificationViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // タッチがcontentViewの内部であれば、ジェスチャーを認識しない
        if contentView.bounds.contains(touch.location(in: contentView)) {
            return false
        }
        return true
    }
}


