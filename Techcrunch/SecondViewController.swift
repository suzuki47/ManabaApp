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

// 2/8 UITableViewDataSource, ↓に挿入
class SecondViewController: UIViewController, UITableViewDelegate, WKNavigationDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var collectionView: UICollectionView!
    //var classes: [ClassData] = []
    let addTaskDialog = AddTaskCustomDialog()
    var context: NSManagedObjectContext!
    //var headers: [String] = []
    var cookies: [HTTPCookie]?
    var classList: [ClassInformation] = []
    var allTaskDataList: [TaskData] = []
    var activeDays: [String] = []
    var maxPeriod = 0
    @IBOutlet weak var nextClassInfoLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBAction func addNewTask(_ sender: UIBarButtonItem) {
        addTaskDialog.addNewTask()
        self.tableView.reloadData() // テーブルビューをリロード
    }
    
    override func viewDidLoad() {
        print("Starting viewDidLoad in SecondViewController")
        super.viewDidLoad()
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height / 1.85), collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ClassCollectionViewCell.self, forCellWithReuseIdentifier: "ClassCell")
        collectionView.backgroundColor = UIColor.white // collectionViewの背景色を黒に設定
        
        
        // collectionViewの背景色を黒に設定
        collectionView.backgroundColor = UIColor.white
        
        // セル間のスペースを設定
        layout.minimumInteritemSpacing = 1 // アイテム間のスペース（縦）
        layout.minimumLineSpacing = 1 // 行間のスペース（横）
        
        // セルのサイズを計算
        let numberOfItemsPerRow: CGFloat = 8
        let spacingBetweenCells: CGFloat = 1
        let totalSpacing = (2 * layout.sectionInset.left) + ((numberOfItemsPerRow - 1) * spacingBetweenCells) // "2 *" は左右のマージン
        let itemWidth = (collectionView.bounds.width - totalSpacing) / numberOfItemsPerRow
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        
        self.view.addSubview(collectionView)
        
        // layoutの更新をトリガー
        collectionView.collectionViewLayout = layout
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        context = appDelegate.persistentContainer.viewContext
        
        
        
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
        
        
        
        // UITableViewの位置を調整
        //tableView.topAnchor.constraint(equalTo: infoView.bottomAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        // TaskDataManagerのインスタンスを生成
        let taskDataManager = TaskDataManager(dataName: "TaskData", context: context)
        //AddNotificationDialog.setTaskDataManager(taskDataManager)
        let classDataManager = ClassDataManager(dataName: "ClassData", context: context)
        
        classDataManager.loadClassData()
        if !classDataManager.checkClassData() {
            classDataManager.resetClassData()
        }
        taskDataManager.getTaskDataFromManaba()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            print("1秒が経過しました。")
            self.allTaskDataList = taskDataManager.allTaskDataList
            print("タスクリストの内容確認（SecondViewController:")
            for taskInfo in self.allTaskDataList {
                print("Task Name: \(taskInfo.taskName), DueDate: \(taskInfo.dueDate), Class Name: \(taskInfo.belongedClassName), Task URL: \(taskInfo.taskURL)")
            }

            //self.collectionView.reloadData()
        }
        classDataManager.getUnChangeableClassDataFromManaba()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            print("1秒が経過しました。")
            self.classList = classDataManager.classList
            print("クラスリストの内容確認（SecondViewController:")
            for classInfo in self.classList {
                print("ID: \(classInfo.id), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url)")
            }
            self.updateActiveDaysAndMaxPeriod()
            //self.collectionView.reloadData()
        
        }
        print("クラスリストの内容確認（SecondViewController:")
        for classInfo in self.classList {
            print("ID: \(classInfo.id), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url)")
        }
        // DispatchQueueを使用して非同期で実行
        DispatchQueue.global(qos: .userInitiated).async {
            taskDataManager.loadTaskData()
            print("TaskDataロード完了！ MainActivity 83")
            taskDataManager.setTaskDataIntoClassData()
            taskDataManager.sortAllTaskDataList()
            /*DispatchQueue.main.async {
                // UIの更新処理など
            }*/
        }
        //fetchData()
        let urlList = [
            "https://ct.ritsumei.ac.jp/ct/home_summary_query",
            "https://ct.ritsumei.ac.jp/ct/home_summary_survey",
            "https://ct.ritsumei.ac.jp/ct/home_summary_report"
        ]

        let classURL = "https://ct.ritsumei.ac.jp/ct/home_course?chglistformat=timetable"
        let cookieString = assembleCookieString()
        let scraper = ManabaScraper(cookiestring: cookieString)
        print("課題スクレイピングテスト：スタート")
        Task {
            do {
                try await scraper.scrapeTaskDataFromManaba(urlList: urlList, cookieString: cookieString)
                print("課題スクレイピングテスト：フィニッシュ")
            } catch {
                print("スクレイピング中にエラーが発生しました: \(error)")
            }
        }
        print("授業スクレイピングテスト（時間割）：スタート")
        Task {
            do {
                try await scraper.getRegisteredClassDataFromManaba(urlString: classURL, cookieString: cookieString)
                print("授業スクレイピングテスト（時間割）：フィニッシュ")
            } catch {
                print("スクレイピング中にエラーが発生しました: \(error)")
            }
        }
        print("授業スクレイピングテスト（時間割以外）：スタート")
        Task {
            do {
                try await scraper.getUnRegisteredClassDataFromManaba(urlString: classURL, cookieString: cookieString)
                print("授業スクレイピングテスト（時間割以外）：フィニッシュ")
            } catch {
                print("スクレイピング中にエラーが発生しました: \(error)")
            }
        }
        print("教授名スクレイピングテスト：スタート")
        Task {
            do {
                try await scraper.getProfessorNameFromManaba(urlString: "https://ct.ritsumei.ac.jp/ct/home_course?chglistformat=list", cookieString: cookieString)
                print("教授名スクレイピングテスト：フィニッシュ")
            } catch {
                print("スクレイピング中にエラーが発生しました: \(error)")
            }
        }
        /* 2/8
        
        tableView.register(CustomCell.self, forCellReuseIdentifier: "CustomCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
         */
        /* 2/27
        tableView.frame = CGRect(x: 0, y: self.view.frame.height / 2, width: self.view.frame.width, height: self.view.frame.height / 2)
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        */
        /* 2/8
        print("Set label text to: \(label.text ?? "nil")")
        
        if let nextClassroom = displayNextClassroomInfo() {
            label.text = "教室情報: \(nextClassroom)"
        } else {
            label.text = "次は空きコマです"
        }
        var taskName: String?
        */
        tableView.reloadData()
        print("Finished viewDidLoad in SecondViewController")
    }
    /*
    func updateActiveDaysAndMaxPeriod() {
        activeDays.removeAll()
        maxPeriod = 0
        
        // 曜日の順序を定義
        let daysOrder = ["月", "火", "水", "木", "金", "土", "日"]
        
        for classInfo in classList {
            print("チェック")
            print(classInfo)
            guard let idInt = Int(classInfo.id) else { continue }
            let dayIndex = idInt % 7 // 0...6の範囲で曜日のインデックスを表す
            let period = idInt / 7 + 1 // 1から始まる時限を表す
            
            let day = daysOrder[dayIndex]
            
            if !activeDays.contains(day) {
                activeDays.append(day)
            }
            maxPeriod = max(maxPeriod, period)
        }
        
        // 曜日をソート
        activeDays.sort { daysOrder.firstIndex(of: $0)! < daysOrder.firstIndex(of: $1)! }
        
        
        // UICollectionViewのレイアウトを更新
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            // セルのサイズを計算
            let numberOfItemsPerRow: CGFloat = CGFloat(activeDays.count + 2)
            let spacingBetweenCells: CGFloat = 1
            let totalSpacing = (2 * layout.sectionInset.left) + ((numberOfItemsPerRow - 1) * spacingBetweenCells)
            let itemWidth = (collectionView.bounds.width - totalSpacing) / numberOfItemsPerRow
            layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
            
            // セクションインセットも必要に応じて更新
            layout.sectionInset = UIEdgeInsets(top: spacingBetweenCells, left: spacingBetweenCells, bottom: spacingBetweenCells, right: spacingBetweenCells)
            
            // レイアウトの更新をトリガー
            collectionView.collectionViewLayout.invalidateLayout()
        }
        print("びゃおう！")
        print("列の数\(activeDays.count)")
        print("行の数\(maxPeriod)")
        collectionView.reloadData()
        
        // その他のUICollectionViewの更新処理
    }*/
    func updateActiveDaysAndMaxPeriod() {
        activeDays = ["月", "火", "水", "木", "金"] // 月曜から金曜まで常に含める
        maxPeriod = 0

        // 土日の授業の有無をチェックし、必要に応じて追加
        let weekend = ["土", "日"]
        var weekendClassesExist = [false, false]
        
        for classInfo in classList {
            let idInt = Int(classInfo.id)!
            let dayIndex = idInt % 7
            let period = idInt / 7 + 1
            maxPeriod = max(maxPeriod, period)
            
            // 土日の授業があるかどうかをチェック
            if dayIndex >= 5 { // 土日の場合
                weekendClassesExist[dayIndex - 5] = true
            }
        }
        
        // 土日の授業があればactiveDaysに追加
        for (index, exists) in weekendClassesExist.enumerated() where exists {
            activeDays.append(weekend[index])
        }

        // UICollectionViewのレイアウトを更新
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            // セルのサイズを計算
            let numberOfItemsPerRow: CGFloat = CGFloat(activeDays.count + 2)
            let spacingBetweenCells: CGFloat = 1
            let totalSpacing = (2 * layout.sectionInset.left) + ((numberOfItemsPerRow - 1) * spacingBetweenCells)
            let itemWidth = (collectionView.bounds.width - totalSpacing) / numberOfItemsPerRow
            layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
            
            // セクションインセットも必要に応じて更新
            layout.sectionInset = UIEdgeInsets(top: spacingBetweenCells, left: spacingBetweenCells, bottom: spacingBetweenCells, right: spacingBetweenCells)
            
            // レイアウトの更新をトリガー
            collectionView.collectionViewLayout.invalidateLayout()
        }
        print("びゃおう！")
        print("列の数\(activeDays.count)")
        print("行の数\(maxPeriod)")
        collectionView.reloadData()
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("列の数\(activeDays.count)")
        print("行の数\(maxPeriod)")
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

            if let classInfo = classList.first(where: { Int($0.id) == classId }) {
                cell.configure(text: "")
                cell.backgroundColor = .green
            } else {
                cell.configure(text: "")
                cell.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
            }
        }

        return cell
    }


    
    /*func classId(day: String, period: Int) -> Int {
        let days = ["月", "火", "水", "木", "金", "土", "日"]
        guard let dayIndex = days.firstIndex(of: day) else { return -1 }
        return dayIndex * 7 + (period - 1)
    }*/

    
    func clearUserDefaults() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
    /*
    func fetchData() {
        let cookieString = assembleCookieString()
        let scraper = ManabaScraper(cookiestring: cookieString)
        
        Task {
            do {
                let classroomInfo = try await scraper.fetchClassroomInfo(usingCookie: cookieString)
                // 成功した場合の処理
                print("スクレイピング成功")
                print("取得した授業情報（SecondViewController）: \(classroomInfo)")
            } catch {
                // エラー処理
                print("エラー: \(error)")
            }
        }
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
    
    func performBackgroundTask() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let backgroundContext = appDelegate.persistentContainer.newBackgroundContext()
        
        backgroundContext.perform {
            // ここでバックグラウンドコンテキストを使用したデータ操作を行う
        }
    }
    
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
        print("チェック開始")
        checkLoginStatus()
        print("チェック完了")
    }
    
    /*　2/8
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
    */
    
    /*タイトル コース名 受付終了日時 タイトル コース名 受付終
     了日時 タイトル コース名 受付終了日時 ダミー（無視してく
     ださい） 33012:データモデリング(A1) § 3301
     3:データベース設計論(A1) 2023-09-30 12:
     00
     */
}
/*
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
    
    
}
*/
