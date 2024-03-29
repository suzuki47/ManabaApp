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
class SecondViewController: UIViewController, UITableViewDelegate, WKNavigationDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource, ClassInfoPopupDelegate {
    var collectionView: UICollectionView!
    //var classes: [ClassData] = []
    let addTaskDialog = AddTaskCustomDialog()
    var context: NSManagedObjectContext!
    //var headers: [String] = []
    var cookies: [HTTPCookie]?
    var classList: [ClassInformation] = []
    var professorList: [ClassAndProfessor] = []
    var unregisteredClassList: [UnregisteredClassInformation] = []
    var taskList: [TaskInformation] = []
    var scrapingTaskList: [TaskInformation] = []
    var allTaskDataList: [TaskData] = []
    var activeDays: [String] = []
    var maxPeriod = 0
    var collectionViewHeightConstraint: NSLayoutConstraint?
    
    // unregisteredClassListにはあるが、changeableClassesに同じnameのものがないデータを格納するための変数
    var classesToRegister = [UnregisteredClassInformation]()

    var tableView: UITableView!
    // ダミーデータの配列
    var dummyData = ["タスク1", "タスク2", "タスク3", "タスク4", "タスク5"]
    
    var classDataManager: ClassDataManager!
    
    override func viewDidLoad() {
        print("Starting viewDidLoad in SecondViewController")
        super.viewDidLoad()
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout) // frameを.zeroに設定
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ClassCollectionViewCell.self, forCellWithReuseIdentifier: "ClassCell")
        collectionView.backgroundColor = UIColor.white
        collectionView.translatesAutoresizingMaskIntoConstraints = false // Auto Layoutを使うために必要
        self.view.addSubview(collectionView)

        // collectionViewの制約を設定
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // 高さは後で動的に調整される
        ])
        collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 200) // 適当な初期値
        collectionViewHeightConstraint?.isActive = true

        
        // collectionViewの背景色を黒に設定
        collectionView.backgroundColor = UIColor.white
        
        // セル間のスペースを設定
        layout.minimumInteritemSpacing = 1 // アイテム間のスペース（縦）
        layout.minimumLineSpacing = 1 // 行間のスペース（横）
        
        self.updateActiveDaysAndMaxPeriod()
        updateCollectionViewHeight()
        
        // layoutの更新をトリガー
        collectionView.collectionViewLayout = layout
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        context = appDelegate.persistentContainer.viewContext
        
        let clearUserDefaultsButton = UIButton(type: .system)
        clearUserDefaultsButton.setTitle("データクリア", for: .normal)
        clearUserDefaultsButton.backgroundColor = .systemRed
        clearUserDefaultsButton.setTitleColor(.white, for: .normal)
        clearUserDefaultsButton.layer.cornerRadius = 5
        clearUserDefaultsButton.addTarget(self, action: #selector(clearUserDefaults), for: .touchUpInside)
        
        // Auto Layoutを使うために必要
        clearUserDefaultsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clearUserDefaultsButton)
        
        // ボタンの制約を設定（左下に配置）
        NSLayoutConstraint.activate([
            clearUserDefaultsButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            clearUserDefaultsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            clearUserDefaultsButton.widthAnchor.constraint(equalToConstant: 120),
            clearUserDefaultsButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
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
        
        // TaskDataManagerのインスタンスを生成
        let taskDataManager = TaskDataManager(dataName: "TaskData", context: context)
        //AddNotificationDialog.setTaskDataManager(taskDataManager)
        classDataManager = ClassDataManager(dataName: "ClassData", context: context)
        
        classDataManager.loadClassData()
        self.classList = classDataManager.classList
        taskDataManager.loadTaskData()
        // ロードしたtaskListを一時的な配列にコピー
        var updatedTaskList = taskDataManager.taskList

        print("ロード後のクラスリストの内容確認（SecondViewController）:")
        for classInfo in self.classList {
            print("ID: \(classInfo.id), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName), 変更可能な授業か:\(classInfo.classIdChangeable)")
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm" // 日付のフォーマットを設定
        
        print("ロード後のタスクリストの内容確認（SecondViewController）:")
        for classInfo in taskList {
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
        var changeableClasses = classDataManager.classList.filter { $0.classIdChangeable }
        

        Task {
            await classDataManager.getUnChangeableClassDataFromManaba()
            await classDataManager.getProfessorNameFromManaba()
            await classDataManager.getChangeableClassDataFromManaba()
            self.unregisteredClassList = classDataManager.unregisteredClassList
            // ロードしたtaskListを一時的な配列にコピー
            var updatedTaskList = taskDataManager.taskList
            
            // updatedTaskListの各要素に対して処理を行う
            for i in 0..<updatedTaskList.count {
                let task = updatedTaskList[i]
                // belongedClassNameがclassListのnameに存在しない、かつunregisteredClassListにも存在しないかチェック
                if !self.classList.contains(where: { $0.name == task.belongedClassName }) &&
                    !self.unregisteredClassList.contains(where: { $0.name == task.belongedClassName }) {
                    // 条件に一致する場合、belongedClassNameを"none"に更新
                    updatedTaskList[i].belongedClassName = "none"
                }
            }
            
            // 処理が完了したら、更新したtaskListをself.taskListに代入
            self.taskList = updatedTaskList
            
            // 未登録クラスのnameリストを作成
            let unregisteredNames = Set(unregisteredClassList.map { $0.name })

            // changeableClassesから、unregisteredClassListに同じnameのものがないデータを削除
            changeableClasses = changeableClasses.filter { unregisteredNames.contains($0.name) }

            // changeableClassesのnameリストを作成
            let changeableNames = Set(changeableClasses.map { $0.name })

            // classesToRegisterに条件に合うものを追加
            for unregisteredClass in unregisteredClassList {
                if !changeableNames.contains(unregisteredClass.name) {
                    classesToRegister.append(unregisteredClass)
                }
            }
            self.classList = classDataManager.classList
            self.classList.append(contentsOf: changeableClasses)
            self.classList.sort { (classInfo1, classInfo2) -> Bool in
                guard let id1 = Int(classInfo1.id), let id2 = Int(classInfo2.id) else {
                    // IDの変換に失敗した場合は、元の順序を保持するためにfalseを返す
                    // 実際には、変換に失敗することが想定外の場合、適切なエラーハンドリングが必要
                    return false
                }
                return id1 < id2
            }
            classDataManager.emptyMyClassDataStore()
            classDataManager.replaceClassDataIntoDB(classInformationList: classList)
            self.unregisteredClassList = classDataManager.unregisteredClassList
            await taskDataManager.getTaskDataFromManaba()
            taskList = taskDataManager.taskList
            /*
            // taskListの各タスクに対して処理を行う
            for i in 0..<taskList.count {
                let task = taskList[i]

                // scrapingTaskListに同じtaskNameを持つタスクが存在するかチェック
                if !scrapingTaskList.contains(where: { $0.taskName == task.taskName }) {
                    // 存在しない場合、hasSubmittedをtrueに設定
                    taskList[i].hasSubmitted = true
                }
            }*/

            taskDataManager.insertTaskDataIntoDB(taskList: taskList)
            print("クラスリストの内容確認（SecondViewController）:")
            for classInfo in self.classList {
                print("ID: \(classInfo.id), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName), 変更可能な授業か:\(classInfo.classIdChangeable)")
            }
            print("クラスリスト（未登録）の内容確認（SecondViewController）:")
            for classInfo in unregisteredClassList {
                print("Name: \(classInfo.name), Professor Name: \(classInfo.professorName), URL: \(classInfo.url)")
            }
            print("タスクリストの内容確認（SecondViewController）:")
            // DateFormatterの設定
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm" // 日付のフォーマットを設定
            
            for classInfo in taskList {
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
            print("時間割に実装済みのその他の授業:\(changeableClasses)")
            print("時間割に未実装のその他の授業:\(classesToRegister)")
            self.updateActiveDaysAndMaxPeriod()
            updateCollectionViewHeight()
            setupTableView()
            // ボタンを最前面に持ってくる
            view.bringSubviewToFront(clearUserDefaultsButton)
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
        
        print("Finished viewDidLoad in SecondViewController")
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = taskList[indexPath.row]
        let popupVC = TaskPopupViewController()
        popupVC.taskName = task.taskName
        popupVC.modalPresentationStyle = .overCurrentContext
        popupVC.modalTransitionStyle = .crossDissolve
        present(popupVC, animated: true, completion: nil)
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // データソースの項目数を返します（例：tasks.count）
        return taskList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskTableViewCell", for: indexPath) as! TaskTableViewCell

        let task = taskList[indexPath.row]
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
        
        for classInfo in classList {
            let idInt = Int(classInfo.id)!
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
            // TODO: 時間割に未実装の授業の追加時に、maxPeriodをUIに反映する
            /*let numberOfRows: CGFloat = CGFloat(maxPeriod)
                let totalVerticalSpacing = (2 * layout.sectionInset.top) + ((numberOfRows - 1) * spacingBetweenCells)
                let itemHeight = (collectionView.bounds.height - totalVerticalSpacing) / numberOfRows
                layout.itemSize = CGSize(width: itemWidth, height: itemHeight)*/
            // セクションインセットも必要に応じて更新
            layout.sectionInset = UIEdgeInsets(top: spacingBetweenCells, left: spacingBetweenCells, bottom: spacingBetweenCells, right: spacingBetweenCells)
            
            // レイアウトの更新をトリガー
            collectionView.collectionViewLayout.invalidateLayout()
        }
        //print("びゃおう！")
        //print("列の数\(activeDays.count)")
        //print("行の数\(maxPeriod)")
        collectionView.reloadData()
    }
    
    func classInfoDidUpdate(_ updatedClassInfo: ClassInformation) {
        print("受け取った更新された授業情報：")
        print("ID: \(updatedClassInfo.id), 名前: \(updatedClassInfo.name), 教室: \(updatedClassInfo.room), URL: \(updatedClassInfo.url), 教授名: \(updatedClassInfo.professorName)")
        // 授業情報を更新
        if let index = classList.firstIndex(where: { $0.name == updatedClassInfo.name }) {
            classList[index] = updatedClassInfo
            print("classListを更新しました。")
        } else {
            print("更新する授業情報が見つかりませんでした。")
        }
        classList.sort { (classInfo1, classInfo2) -> Bool in
            // String型のIDをIntに変換
            guard let id1 = Int(classInfo1.id), let id2 = Int(classInfo2.id) else {
                return false
            }
            // 数値としての比較
            return id1 < id2
        }
        // 更新後のclassListの内容を確認
        print("更新後のclassListの内容確認：")
        classList.forEach { classInfo in
            print("ID: \(classInfo.id), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName)")
        }
        // コレクションビューを更新
        self.updateActiveDaysAndMaxPeriod()
        updateCollectionViewHeight()
        setupTableView()
    }
    
    func showClassInfoPopup(for classInfo: ClassInformation) {
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
            let newClass = ClassInformation(id: String(id), name: unregisteredClass.name, room: location, url: unregisteredClass.url, professorName: unregisteredClass.professorName, classIdChangeable: true)
            classList.append(newClass)
            classDataManager.replaceClassDataIntoDB(classInformationList: classList)
            // 使用した未登録授業情報をclassesToRegisterから削除
            classesToRegister.removeFirst()
        }
        classList.sort { (classInfo1, classInfo2) -> Bool in
            // String型のIDをIntに変換
            guard let id1 = Int(classInfo1.id), let id2 = Int(classInfo2.id) else {
                // 変換に失敗した場合は、どのように扱うかによります（ここでは単純にfalseを返していますが、
                // 実際には失敗した場合のロジックが必要かもしれません）
                return false
            }
            // 数値としての比較
            return id1 < id2
        }
        print("クラスリストの内容確認（未登録追加後）:")
        for classInfo in self.classList {
            print("ID: \(classInfo.id), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url), 教授名: \(classInfo.professorName)")
        }
        
        // コレクションビューを更新
        self.updateActiveDaysAndMaxPeriod()
        updateCollectionViewHeight()
        setupTableView()
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
        let classId = dayIndex + (period - 1) * 7
        
        // 対応するClassInformationオブジェクトを取得してポップアップ表示
        if let classInfo = classList.first(where: { Int($0.id) == classId }) {
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
            self?.classDataManager.replaceClassDataIntoDB(classInformationList: self?.classList ?? [])
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
            
            if let classInfo = classList.first(where: { Int($0.id) == classId && $0.classIdChangeable }) {
                cell.configure(text: "") // 初期テキスト設定
                cell.backgroundColor = .green // 一旦緑に設定
                cell.configure(text: "↕️↔️") // classIdChangeableがtrueの場合は矢印記号を表示
                
                // taskListに該当する未提出のタスクがあるかチェック
                let hasUnsubmittedTask = taskList.contains(where: { $0.belongedClassName == classInfo.name && !$0.hasSubmitted })
                if hasUnsubmittedTask {
                    cell.backgroundColor = .red // 未提出のタスクがあれば赤に変更
                }
            } else if classList.contains(where: { Int($0.id) == classId }) {
                // classIdChangeableがfalseでも授業情報が存在する場合
                cell.configure(text: "") // テキストを空に設定
                cell.backgroundColor = .green // 背景色を緑に設定
            } else {
                // 該当するclassInfoがない場合は背景色を白に
                cell.configure(text: "")
                cell.backgroundColor = .white
            }
            
        }
        return cell
    }
    /*
    func clearUserDefaults() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
    */
    @objc func clearUserDefaults() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        // 必要に応じてUIの更新や確認メッセージを表示
        print("UserDefaultsがクリアされました。")
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
        //tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear in SecondViewController")
        print("チェック開始")
        checkLoginStatus()
        print("チェック完了")
    }
    
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
