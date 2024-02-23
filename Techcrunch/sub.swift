//
//  sub.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2024/02/08.
//
//
//  SecondViewController.swift
//  Techcrunch
//
//  Created by 鈴木悠太 on 2023/07/10.
//
/*
import Foundation
import UIKit
import UserNotifications
import CoreData
import WebKit


class SecondViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, WKNavigationDelegate{
    
    var isLoginMicrosoftOnlineReached = false
    var loginChecked = false
    var loadCount = 0
    
    let addTaskDialog = AddTaskCustomDialog()
    
    var managedObjectContext: NSManagedObjectContext?
    
    //weak var classroomInfoDelegate: ClassroomInfoDelegate?
    
    var classroomInfoData: [String]?
    var classroomInfo: [String] = [] {
        didSet {
            // classroomInfo が更新されたタイミングでデータをログに表示
            print("せかんどびゅーでの教室情報")
            print("Received classroomInfo in SecondViewController: \(classroomInfo)")
        }
    }
    
    var headers: [String] = []
    
    
    //var taskName: String?
    var notificationDates: [Date] = []
    
    
    let classTimes: [(start: Int, end: Int)] = [
        (540, 630),
        (640, 730),
        (780, 870),
        (880, 970),
        (980, 1070),
        (1080, 1170),
        (1180, 1270)
    ]
    
    private let webView: WKWebView = {
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = true
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        config.preferences = prefs
        config.defaultWebpagePreferences = pagePrefs
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.translatesAutoresizingMaskIntoConstraints = false
        return webview
    }()
    
    var cookies: [HTTPCookie]?
    
    override func viewDidLoad() {
        print("Starting viewDidLoad in SecondViewController")
        super.viewDidLoad()
        
        

        
        /*let url = URL(string: "https://ct.ritsumei.ac.jp/ct/home_summary_report")! // 目的のURLを設定
        self.cookies = HTTPCookieStorage.shared.cookies(for: url)
        if let cookies = self.cookies {
         var hasSessionId = false
         print("クッキー")
         print(cookies)
         for cookie in cookies {
         print("Cookie: \(cookie)")
         if cookie.name == "sessionid" {
         hasSessionId = true
         break
         }
         }
         
         if hasSessionId {
         // 'sessionid'クッキーがある場合の処理
         print("ログインできてたよ！！！")
         // ここでログイン状態が確認された後の処理を行う
         } else {
         // 'sessionid'クッキーがない場合の処理
         print("ログインできてなかったよ！！！")
         // ここでログインが必要な処理を行う
         }
         }*/
        
        // infoViewの初期化
        let infoView = UIView()
        infoView.backgroundColor = .lightGray
        infoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoView)
        
        // ラベルの追加
        let label = UILabel()
        label.text = "教室情報"
        label.translatesAutoresizingMaskIntoConstraints = false
        infoView.addSubview(label)
        
        // infoViewの制約
        NSLayoutConstraint.activate([
            infoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            infoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            infoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            infoView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // webView関連の設定
        self.webView.isHidden = true
        self.webView.navigationDelegate = self
        guard let url = URL(string: "https://ct.ritsumei.ac.jp/ct/home_summary_report") else { return }
        self.webView.load(URLRequest(url: url))
        self.view.addSubview(self.webView)
        //let webView = WKWebView() // 既存のWKWebViewインスタンス
        self.webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            print("ここから")
            for cookie in cookies {
                print("\(cookie.name) = \(cookie.value)")
                print(cookie.domain)
            }
            print("ここまで")
        }

        
        
        
        // webViewの制約
        NSLayoutConstraint.activate([
            self.webView.topAnchor.constraint(equalTo: infoView.bottomAnchor),
            self.webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            self.webView.rightAnchor.constraint(equalTo: view.rightAnchor),
            self.webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        /*
         //webview関連ここまで
         DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
         if !self.loginChecked {
         print("ログインするよ")
         let loginVC = LoginViewController()
         loginVC.modalPresentationStyle = .formSheet // または .pageSheet など
         self.present(loginVC, animated: true, completion: nil)
         } else {
         print("新たにログインしないよ")
         /*let loginVC = LoginViewController()
          loginVC.modalPresentationStyle = .formSheet // または .pageSheet など
          self.present(loginVC, animated: true, completion: nil)*/
         }
         print("5秒経過しました")
         }
         
         Task{
         do{
         
         }
         }
         */
        // この関数を呼び出してログイン処理を開始する
        //loginIfNeeded()
        
        
        
        //Core Data のコンテキストの取得
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        managedObjectContext = appDelegate.persistentContainer.viewContext
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if granted {
                print("Notification authorization granted")
            } else {
                print("Notification authorization denied")
            }
        }
        
        addTaskDialog.viewController = self
        
        view.backgroundColor = UIColor(red: 0.5, green: 0.8, blue: 0.5, alpha: 1.0)
        
        
        
        tableView.register(CustomCell.self, forCellReuseIdentifier: "CustomCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        
        
        print("Set label text to: \(label.text ?? "nil")")
        
        if let nextClassroom = displayNextClassroomInfo() {
            label.text = "教室情報: \(nextClassroom)"
        } else {
            label.text = "次は空きコマです"
        }
        var taskName: String?
        //とりあえず2024.01.03
        /*
         //通知の日付の取得
         if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
         self.notificationDates = DataManager.getDataStores().first?.notificationDates as? [Date] ?? []
         }
         */
        
        NSLayoutConstraint.activate([
            // infoViewの制約
            infoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            infoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            infoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            infoView.heightAnchor.constraint(equalToConstant: 50), // この高さを変更して好みのサイズに調整
            
            // ラベルの制約
            label.centerXAnchor.constraint(equalTo: infoView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: infoView.centerYAnchor)
        ])
        
        // UITableViewの位置を調整
        tableView.topAnchor.constraint(equalTo: infoView.bottomAnchor).isActive = true
        /*
         //TODO: これをManabaScraperに移動
         for header in headers {
         // Debugging statements
         print("Header: \(header)")
         
         // Updated regular expression pattern to extract task name
         let pattern = "^(.*?)(\\d{4}-\\d{2}-\\d{2}|\\d{4}年\\d{1,2}月\\d{1,2}日|\\d+:\\w+\\()"
         let regex = try! NSRegularExpression(pattern: pattern)
         
         if let match = regex.firstMatch(in: header, options: [], range: NSRange(location: 0, length: header.utf16.count)) {
         let nameRange = Range(match.range(at: 1), in: header)!
         let name = String(header[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
         
         let components = header.split(separator: " ")
         let dueDateString = String(components[components.count - 2]) + " " + String(components.last ?? "")
         
         // Debugging statements
         print("Name: \(name)")
         print("Due date string: \(dueDateString)")
         
         // Convert the due date to a Date
         let dateFormatter = DateFormatter()
         dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
         if let dueDate = dateFormatter.date(from: dueDateString) {
         // Create a new task
         let newTask = taskData(name: name, dueDate: dueDate, detail: "", taskType: 0)
         TaskData.shared.tasks.append(newTask)
         } else {
         print("Error: could not parse date string \(dueDateString)")
         }
         } else {
         print("Error: could not extract task name from header \(header)")
         }
         }
         */
        var cookiesString = ""
        if let cookies = cookies {
            for cookie in cookies {
                let cookieString = "Name: \(cookie.name), Value: \(cookie.value), Path: \(cookie.path), Domain: \(cookie.domain)"
                cookiesString += cookieString + "; "
            }
        }
        let manabaScraper = ManabaScraper(cookiestring: cookiesString)
        
        var pairTask = [(String, String)]()
        Task{
            do{
                pairTask = try await manabaScraper.receiveRequest(dataName: "TaskData")
                print("ペア型タスク:\(pairTask)")
            } catch {
                print("Failed: \(error)")
            }
        }
        
        print("やああああああああああああああ")
        /*print(headers)*/
        print("やああああああああああああああ")
        //とりあえず2024.01.03
        //let taskdatastores = DataManager.getDataStores()
        //とりあえず2024.01.03
        /*
         for taskdatastore in taskdatastores {
         if let name = taskdatastore.name,
         let dueDate = taskdatastore.dueDate,
         let detail = taskdatastore.detail {
         //print("kikikikiikiiiki")
         //print(TaskData.taskDates.count)
         DataManager.addNewTaskAndSave(name: name, dueDate: dueDate, detail: detail, taskType: Int(taskdatastore.taskType))
         print("いいいいいいいいいいいいいいいいいいいいいい")
         } else {
         print("One or more values are nil for a taskdatastore")
         }
         }
         */
        print("おりゃあああああああ")
        tableView.reloadData()
        //ここ10/19
        //NotifyManager.shared.scheduleClassroomNotification(nextClass: yourNextClassInfo)
        
        
        print(classroomInfo)
        print("Finished viewDidLoad in SecondViewController")
        //とりあえず2024.01.03
        //DataManager.updateTaskDataFromCoreData()
        print(TaskData.shared)
        //とりあえず2024.01.03
        //DataManager.saveSharedTaskData()
        
    }
    
    /*func checkCookies(completion: @escaping (Bool) -> Void) {
     let url = URL(string: "https://ct.ritsumei.ac.jp/ct/home_summary_report")!
     self.cookies = HTTPCookieStorage.shared.cookies(for: url)
     var hasSessionId = false
     
     if let cookies = self.cookies {
     for cookie in cookies {
     print("Cookie: \(cookie.name) = \(cookie.value)")
     if cookie.name == "sessionid" {
     hasSessionId = true
     break
     }
     }
     }
     print("セッションIDのクッキーが見つかりましたか？ \(hasSessionId)")
     completion(hasSessionId)
     }
     
     
     func loginIfNeeded() {
     checkCookies { isLoggedIn in
     DispatchQueue.main.async {
     print("クッキーチェックが完了しました。ログイン状態: \(isLoggedIn)")
     if !isLoggedIn {
     print("ログインしていません。LoginViewControllerを表示します。")
     self.presentLoginViewController()
     } else {
     print("既にログインしています。何もする必要はありません。")
     // 既にログインしている場合の処理をここに記述
     }
     }
     }
     }*/
    
    
    /*func presentLoginViewController() {
     guard self.presentedViewController == nil else {
     return
     }
     let loginVC = LoginViewController()
     loginVC.modalPresentationStyle = .formSheet // または .pageSheet など
     self.present(loginVC, animated: true, completion: nil)
     }*/
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear in SecondViewController")
        // CoreDataからデータを取得
        //fetchAndPrintTaskDataStore()
        
        // テーブルビューを更新
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear in SecondViewController")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        /*guard let url = webView.url else { return }
         print("ページの読み込み完了: \(url.absoluteString)")
         
         if url.absoluteString.contains("login.microsoftonline.com") {
         // Microsoftのログインページに到達
         isLoginMicrosoftOnlineReached = true
         print("1．今の: \(url.absoluteString)")
         print(isLoginMicrosoftOnlineReached)
         } else if isLoginMicrosoftOnlineReached {
         print("2．今の: \(url.absoluteString)")
         if url.absoluteString.contains("https://ct.ritsumei.ac.jp/ct/home_summary_report") {
         print("ログインできてたよ")
         isLoginMicrosoftOnlineReached = false
         // ログインしている場合の処理
         } /*else {
            print("ログインしていません。LoginViewControllerを表示します。")
            self.presentLoginViewController()
            isLoginMicrosoftOnlineReached = false
            }*/
         }*/
        
        loadCount += 1
        print("ページの読み込み完了: \(webView.url?.absoluteString ?? "unknown"), 回数: \(loadCount)")
        
        if loadCount == 2 {
            // 2回目の読み込みが完了したが、すぐには処理を行わない
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let strongSelf = self else { return }
                if strongSelf.loadCount == 2 {
                    // 追加の読み込みがない場合
                    print("ログインしていません。LoginViewControllerを表示します。")
                    strongSelf.presentLoginViewController()
                }
            }
        } else if loadCount > 2 {
            // 3回以上の読み込みでログイン済みと判断
            print("ログインできてたよ")
            // ログイン済みの場合の処理をここに記述
        }
    }
    
    /*
     func checkLoginStatus(_ webView: WKWebView) {
     let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
     cookieStore.getAllCookies { cookies in
     var hasSessionId = false
     
     for cookie in cookies {
     if cookie.name == "sessionid" {
     hasSessionId = true
     break
     }
     }
     
     if !hasSessionId {
     print("ログインしていません。LoginViewControllerを表示します。")
     self.presentLoginViewController()
     } else {
     print("ログインしています。")
     // ログインしている場合の処理
     }
     }
     }*/
    
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if let url = webView.url {
            print("ページの読み込みを開始: \(url.absoluteString)")
        }
    }
    
    
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("ページの読み込み失敗: \(error.localizedDescription)")
    }
    
    func presentLoginViewController() {
        // ログイン画面をモーダル表示する処理
        let loginVC = LoginViewController()
        loginVC.modalPresentationStyle = .formSheet
        self.present(loginVC, animated: true, completion: nil)
    }
    
    
    
    
    
    /*
     func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!){
     // ページの読み込みが完了したときの処理
     print("2222222222222222222")
     }
     
     func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
     // ページの読み込みに失敗したときの処理
     }
     */
    //セクションごとの行数の定義
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("えええええええええええええ")
        print(TaskData.shared.tasks.count)
        return TaskData.shared.tasks.count
        
    }
    //行のスワイプアクションの設定
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "") { [weak self] (action, view, completionHandler) in
            //とりあえず2024.01.03
            // DataManagerを使用してデータを削除
            //DataManager.removeData(at: indexPath.row)
            
            // テーブルビューから行を削除
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
    
    //セルの内容の設定
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get a reusable cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomCell
        print("Setting up cell for indexPath: \(indexPath) in SecondViewController")
        cell.delegate = self
        cell.managedObjectContext = self.managedObjectContext // ここでセルの managedObjectContext を設定
        
        
        // Get the corresponding task
        let taskDate = TaskData.shared.tasks[indexPath.row]
        cell.taskData = taskDate
        
        // Set the text of the cell's labels
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        
        let dueDateString = formatter.string(from: taskDate.dueDate)
        cell.taskLabel.text = taskDate.name
        cell.dueDateLabel.text = dueDateString
        
        let hasNotification = !taskDate.notificationDates.isEmpty
        cell.updateNotificationIcon(isNotified: hasNotification)
        
        // Check if the task has a notification set
        //let taskDate = taskDates[indexPath.row]
        if taskDate.isNotified {
            cell.button.tintColor = UIColor.blue
        } else {
            cell.button.tintColor = UIColor.red
        }
        return cell
    }
    //セルの高さの設定
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55 // Or whatever height is appropriate for your labels.
    }
    //セルの選択時のアクション(遷移)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // タスクを取得
        let taskDate = TaskData.shared.tasks[indexPath.row]
        
        // 新しいViewControllerをStoryboardからインスタンス化
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let notificationCustomAdapter = storyboard.instantiateViewController(withIdentifier: "NotificationCustomAdapter") as? NotificationCustomAdapter {
            
            // タスクの詳細、通知日時、および名前を設定
            notificationCustomAdapter.taskName = taskDate.name
            notificationCustomAdapter.taskDetail = taskDate.detail
            notificationCustomAdapter.notificationDates = taskDate.notificationDates
            
            // delegateを設定
            notificationCustomAdapter.delegate = self
            
            // モーダルを表示
            present(notificationCustomAdapter, animated: true, completion: nil)
        }
    }
    
    
    @IBOutlet weak var nextClassInfoLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func addNewTask(_ sender: UIBarButtonItem) {
        addTaskDialog.addNewTask()
        self.tableView.reloadData() // テーブルビューをリロード
    }
    
    //Core Dataのコンテナでデータベース操作を行うためのもの
    private static var persistentContainer: NSPersistentCloudKitContainer! = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    //新しいTaskDataStoreエンティティを作成
    static func newDataStore() -> DataStore {
        let context = persistentContainer.viewContext
        let datastore = NSEntityDescription.insertNewObject(forEntityName: "DataStore", into: context) as! DataStore
        return datastore
    }
    
    //タスク追加ボタン
    func didTapButton(in cell: CustomCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let taskDate = TaskData.shared.tasks[indexPath.row]
            
            // 新しいViewControllerをStoryboardからインスタンス化
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let notificationCustomAdapter = storyboard.instantiateViewController(withIdentifier: "NotificationCustomAdapter") as? NotificationCustomAdapter {
                
                // タスクの詳細、通知日時、および名前を設定
                notificationCustomAdapter.taskName = taskDate.name
                notificationCustomAdapter.taskDetail = taskDate.detail
                notificationCustomAdapter.notificationDates = taskDate.notificationDates
                
                // モーダルを表示
                present(notificationCustomAdapter, animated: true, completion: nil)
            }
            
            // 通知設定のアラートダイアログ
            let alert = UIAlertController(title: "通知設定", message: "通知の日時を選択してください", preferredStyle: .alert)
            alert.addTextField { textField in
                let datePicker = UIDatePicker()
                datePicker.datePickerMode = .dateAndTime
                textField.inputView = datePicker
                textField.placeholder = "日時を選択"
            }
            
            let okAction = UIAlertAction(title: "OK", style: .default) { [weak self, weak alert] _ in
                guard let textField = alert?.textFields?[0], let datePicker = textField.inputView as? UIDatePicker else { return }
                let selectedDate = datePicker.date
                
                // ここ10/19
                //NotifyManager.shared.scheduleNotification(for: taskName, dueDate: dueDate)
                
                // Update the UI if needed
                cell.updateNotificationIcon(isNotified: true)
                
                // Update the taskDates model
                var taskToUpdate = TaskData.shared.tasks[indexPath.row]
                taskToUpdate.addNotificationDate(selectedDate)
                TaskData.shared.tasks[indexPath.row] = taskToUpdate
                
                
                // Create and save the taskdatastore
                let datastore = SecondViewController.newDataStore()
                datastore.title = taskDate.name
                //とりあえず2024.01.03(DateをStringにしたため)
                //datastore.subtitle = taskDate.dueDate
                datastore.detail = taskDate.detail
                //datastore.taskType = 1
                //datastore.isNotified = true
                
                // Save the context
                do {
                    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                    try context.save()
                } catch {
                    print("Failed to save context after adding notification: \(error)")
                }
                
                // DataManagerを使用して新しいタスクを追加し保存
                //DataManager.addNewTaskAndSave(name: taskName, dueDate: dueDate, detail: taskDetail, taskType: 1)
                
                
                // Reload the cell to display the new notification date
                self?.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
            
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true, completion: nil)
        }
        tableView.reloadData()
    }
    //仮置き
    func didReceiveClassroomInfo(_ info: [String]) {
        // classroomInfo を受け取った時の処理をここに書きます。
        // 例: self.classroomInfo = info
    }
    
    func findNextClassInfo() -> (periodStr: String, room: String)? {
        guard let classroomInfoData = classroomInfoData else {
            return nil
        }
        
        // 現在の時刻を取得
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinute = hour * 60 + minute
        
        // 現在の曜日の文字列を取得
        let weekday = calendar.component(.weekday, from: now)
        let days = ["日", "月", "火", "水", "木", "金", "土"]
        let currentDay = days[weekday - 1]
        
        for (index, period) in classTimes.enumerated() {
            let periodStr = "\(currentDay)\(index + 1)"
            if period.start > currentMinute {
                for classInfo in classroomInfoData {
                    if classInfo.contains(periodStr) {
                        if let room = classInfo.split(separator: ":").last {
                            return (periodStr, String(room))
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    func getNextClassInfo() -> (nextTiming: Date?, className: String, classRoom: String)? {
        if let nextClassInfo = findNextClassInfo() {
            let periodStr = nextClassInfo.periodStr
            let room = nextClassInfo.room
            
            let periodIndex = Int(String(periodStr.last!)) ?? 0
            let period = classTimes[periodIndex - 1]
            
            let startHour = period.start / 60
            let startMinute = period.start % 60
            let nextClassDate = Calendar.current.date(bySettingHour: startHour, minute: startMinute, second: 0, of: Date())
            
            return (nextClassDate, "授業 \(periodIndex)", room)
        }
        
        return nil
    }
    
    func displayNextClassroomInfo() -> String? {
        if let nextClassInfo = findNextClassInfo() {
            return "次の教室は\(nextClassInfo.room)です"
        }
        return "次は空きコマです"
    }
    
    //教室名の通知設定
    /*func scheduleClassroomNotification() {
     guard let nextClass = getNextClassInfo(), let nextTiming = nextClass.nextTiming else {
     print("No next class found")
     return
     }
     
     let content = UNMutableNotificationContent()
     content.title = "次の授業情報"
     content.body = "30分後に「\(nextClass.className)」が開始されます。教室: \(nextClass.classRoom)"
     
     // 授業開始の30分前の時間を計算
     let fireDate = nextTiming.addingTimeInterval(-30 * 60)
     let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
     let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
     
     let request = UNNotificationRequest(identifier: "nextClassNotification", content: content, trigger: trigger)
     
     let notificationCenter = UNUserNotificationCenter.current()
     notificationCenter.add(request) { (error) in
     if let error = error {
     print("Notification Error:", error)
     }
     }
     
     // 授業開始の30分後の通知をスケジュールして、前の通知を削除する
     let clearTriggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextTiming.addingTimeInterval(30 * 60))
     let clearTrigger = UNCalendarNotificationTrigger(dateMatching: clearTriggerDate, repeats: false)
     let clearContent = UNMutableNotificationContent() // 何も表示しない通知
     let clearRequest = UNNotificationRequest(identifier: "clearNextClassNotification", content: clearContent, trigger: clearTrigger)
     
     notificationCenter.add(clearRequest) { (error) in
     if error == nil {
     // 前の通知を削除
     notificationCenter.removeDeliveredNotifications(withIdentifiers: ["nextClassNotification"])
     }
     }
     }*/
    //taskDataStoreとtaskDataの確認
    func fetchAndPrintTaskDataStore() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Error: Could not get app delegate")
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<DataStore> = DataStore.fetchRequest()
        
        do {
            let results = try context.fetch(fetchRequest)
            for taskDataStore in results {
                print("--------------------------------")
                print("TaskDataStore Contents:")
                print("Task Name: \(taskDataStore.title ?? "N/A")")
                print("Detail: \(taskDataStore.detail ?? "N/A")")
                //とりあえず2024.01.03
                //print("Due Date: \(taskDataStore.subtitle ?? Date())")
                //print("Is Notified: \(taskDataStore.isNotified)")
                //とりあえず2024.01.03
                /*
                 if let notificationDates = taskDataStore.notificationDates as? [Date] {
                 for (index, date) in notificationDates.enumerated() {
                 print("Notification Date \(index + 1): \(date)")
                 }
                 }
                 */
                //とりあえず2024.01.03
                /*
                 let taskData = convertToTaskData(from: taskDataStore)
                 print("\nTaskData Contents:")
                 print("Task Name: \(taskData.name)")
                 print("Detail: \(taskData.detail)")
                 print("Due Date: \(taskData.dueDate)")
                 for (index, date) in taskData.notificationDates.enumerated() {
                 print("Notification Date \(index + 1): \(date)")
                 }
                 print("Is Notified: \(taskData.isNotified)")
                 */
            }
        } catch {
            print("Error: \(error)")
        }
    }
    //とりあえず2024.01.03
    /*
     //TaskDataStoreエンティティからTaskDataモデルへの変換
     func convertToTaskData(from store: DataStore) -> taskData {
     let name = store.title ?? ""
     //とりあえず2024.01.03
     //let dueDate = store.subtitle ?? Date()
     let detail = store.detail ?? ""
     //let taskType = Int(store.taskType)
     //とりあえず2024.01.03
     //var taskData1 = taskData(name: name, dueDate: dueDate, detail: detail, taskType: taskType)
     //とりあえず2024.01.03
     /*
      if let notificationDates = store.notificationDates as? [Date] {
      notificationDates.forEach { taskData1.addNotificationDate($0) }
      }
      */
     return taskData1
     
     }
     */
    //taskDataStoreとtaskDataの確認ボタン
    @IBAction func checkStoredData(_ sender: Any) {
        fetchAndPrintTaskDataStore()
    }
    
    /*タイトル コース名 受付終了日時 タイトル コース名 受付終
     了日時 タイトル コース名 受付終了日時 ダミー（無視してく
     ださい） 33012:データモデリング(A1) § 3301
     3:データベース設計論(A1) 2023-09-30 12:
     00
     */
}
//CustomCellDelegateプロトコルを準拠するための拡張
//10/19
extension SecondViewController: CustomCellDelegate {
    func scheduleNotification(for taskName: String, dueDate: Date) {
        print("f")
    }
    
    //通知の日付が更新されたとき
    func didUpdateNotificationDates(with updatedTaskData: TaskData) {
        print("ki")
    }
    //指定されたタスク名と期限日時を使用して通知をスケジュールする
    /*func scheduleNotification(for taskName: String, dueDate: Date) {
     let content = UNMutableNotificationContent()
     content.title = "タスク通知"
     content.body = "タスク「\(taskName)」の期限時間です！"
     
     let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
     let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
     
     let request = UNNotificationRequest(identifier: taskName, content: content, trigger: trigger)
     
     let center = UNUserNotificationCenter.current()
     center.add(request) { error in
     if let error = error {
     print("Error: \(error)")
     }
     }
     
     // Find the corresponding TaskData and update its _notificationDates
     if let taskIndex = TaskData.taskDates.firstIndex(where: { $0.name == taskName }) {
     TaskData.taskDates[taskIndex].addNotificationDate(dueDate)
     }
     
     // Reload the table view to reflect the change
     tableView.reloadData()
     }*/
    
    
}
// MARK: - DetailViewControllerDelegate
extension SecondViewController: NotificationCustomAdapterDelegate {
    //特定のタスクの通知日付が更新されたときに変更を反映する
    func didUpdateNotificationDates(for taskName: String, _ dates: [Date]) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Error: Could not get app delegate")
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<DataStore> = DataStore.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", taskName)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let taskDataStore = results.first {
                //とりあえず2024.01.03
                //taskDataStore.notificationDates = dates as NSArray
                try context.save()
            }
        } catch {
            print("Error: \(error)")
        }
        tableView.reloadData()
    }
}
*/
