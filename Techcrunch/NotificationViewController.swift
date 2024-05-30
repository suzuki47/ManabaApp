import UIKit
import UserNotifications

class NotificationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DatePickerViewControllerDelegate {
    
    var titleLabel: UILabel!
    var subtitleLabel: UILabel!
    var tableView: UITableView!
    var addButton: UIButton!
    
    // 追加: 通知タイミングの配列
    var notificationTiming: [Date] = []
    
    var notifications: [(date: String, time: String)] = []
    
    // 追加: 課題名と期限日時のプロパティ
    var taskName: String = ""
    var dueDate: Date = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTitleLabel()
        setupSubtitleLabel()
        setupTableView()
        setupAddButton()
        self.view.backgroundColor = .white
        
        // タイトルラベルに課題名を設定
        titleLabel.text = taskName
        
        // 受け取ったnotificationTimingを元に表示するデータを設定
        setupNotifications()
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
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
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
        datePickerVC.modalPresentationStyle = .fullScreen
        present(datePickerVC, animated: true, completion: nil)
    }
    
    @objc func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    func didPickDate(date: Date) {
        notificationTiming.append(date)
        
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
            scheduleNotification(at: date, title: taskName, subTitle: "Due date: \(dueDateString)")
        }
    }
    
    func scheduleNotification(at date: Date, title: String, subTitle: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = subTitle
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = UUID().uuidString
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
            notifications.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
