//
//  ClassInfoPopupViewController.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2024/03/07.
//

import UIKit
import CoreData

protocol ClassInfoPopupDelegate: AnyObject {
    func classInfoDidUpdate(_ updatedClassInfo: ClassData)
    func classInfoPopupDidClose()
}

class ClassInfoPopupViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UITableViewDelegate, UITableViewDataSource {
    weak var delegate: ClassInfoPopupDelegate?
    var classInfo: ClassData?
    var classDataManager: ClassDataManager!
    private var tableView: UITableView!
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let classNameLabel = UILabel()
    private let classRoomLabel = UILabel()
    private let professorNameLabel = UILabel()
    //private let closeButton = UIButton()
    private let urlButton = UIButton()
    private let editButton = UIButton()
    private let alarmSwitch = UISwitch()
    private var collectionView: UICollectionView!
    
    // CoreDataのコンテキスト
    var managedObjectContext: NSManagedObjectContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupEditButton()
        setupAlarmSwitch()  // スイッチのレイアウト設定
        setupTableView()
        /*
        // タップジェスチャをビューに追加
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        view.addGestureRecognizer(tapGesture)
        */
        // タップジェスチャをビューに追加
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // CoreDataのコンテキストを取得
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            managedObjectContext = appDelegate.persistentContainer.viewContext
        }
        
        collectionView.delegate = self
        collectionView.dataSource = self
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @objc private func viewTapped(gesture: UITapGestureRecognizer) {
        // タップされた位置を取得
        let location = gesture.location(in: view)
        
        // タップされた位置がcontentViewの外側であるか判定
        if !contentView.frame.contains(location) {
            // 外側であればポップアップを閉じる
            closePopup()
        }
    }
    
    private func setupLayout() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 12
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        
        let titleText = "選択した授業"
        let titleAttributedString = NSMutableAttributedString(string: titleText)
        titleAttributedString.addAttributes([.font: UIFont.boldSystemFont(ofSize: titleLabel.font.pointSize)], range: NSRange(location: 0, length: titleText.count))
        titleLabel.attributedText = titleAttributedString
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        let classInfoName = classInfo?.name ?? ""
        let pattern = "\\d{5}:"
        let truncatedClassInfoName = classInfoName.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        let classNameText = "🎓教科名\n\(truncatedClassInfoName)"
        let classNameAttributedString = NSMutableAttributedString(string: classNameText)
        let classNameRange = (classNameText as NSString).range(of: "教科名")
        classNameAttributedString.addAttributes([.font: UIFont.boldSystemFont(ofSize: classNameLabel.font.pointSize)], range: classNameRange)
        classNameLabel.attributedText = classNameAttributedString
        classNameLabel.numberOfLines = 0
        classNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(classNameLabel)
        /*
        let classRoomText = "🔶時間・教室\n\(classInfo?.room ?? "")"
        let classRoomAttributedString = NSMutableAttributedString(string: classRoomText)
        let classRoomRange = (classRoomText as NSString).range(of: "時間・教室")
        classRoomAttributedString.addAttributes([.font: UIFont.boldSystemFont(ofSize: classRoomLabel.font.pointSize)], range: classRoomRange)
        classRoomLabel.attributedText = classRoomAttributedString
        classRoomLabel.numberOfLines = 0
        classRoomLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(classRoomLabel)
        */
        let professorNameText = "👤担当教授名\n\(classInfo?.professorName ?? "")"
        let professorNameAttributedString = NSMutableAttributedString(string: professorNameText)
        let professorNameRange = (professorNameText as NSString).range(of: "担当教授名")
        professorNameAttributedString.addAttributes([.font: UIFont.boldSystemFont(ofSize: professorNameLabel.font.pointSize)], range: professorNameRange)
        professorNameLabel.attributedText = professorNameAttributedString
        professorNameLabel.numberOfLines = 0
        professorNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(professorNameLabel)
        /*
        closeButton.setTitle("×", for: .normal)
        closeButton.backgroundColor = .lightGray
        closeButton.layer.cornerRadius = 5
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closePopup), for: .touchUpInside)
        contentView.addSubview(closeButton)
         */
        // URLボタンの設定
        urlButton.setTitle("授業ページ⇨", for: .normal)
        urlButton.backgroundColor = .clear // 背景色をクリアに設定
        urlButton.layer.cornerRadius = 0 // 角の丸みを取り除く
        urlButton.layer.borderWidth = 0 // 枠線を取り除く
        urlButton.setTitleColor(.black, for: .normal) // タイトルの色を設定
        urlButton.titleLabel?.font = UIFont.systemFont(ofSize: 16) // フォントサイズを設定
        urlButton.translatesAutoresizingMaskIntoConstraints = false
        urlButton.addTarget(self, action: #selector(openURL), for: .touchUpInside)
        contentView.addSubview(urlButton)

        alarmSwitch.translatesAutoresizingMaskIntoConstraints = false
        alarmSwitch.addTarget(self, action: #selector(alarmSwitchChanged), for: .valueChanged)
        contentView.addSubview(alarmSwitch)
        
        setupCollectionView()
        setupToggleButton()
        setupTableView()
        
        setupConstraints()
    }
    
    private func setupTableView() {
        tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TableViewCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: professorNameLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tableView.heightAnchor.constraint(equalToConstant: 100)  // 高さは適宜調整してください
        ])
    }
    
    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return classDataManager.classList.filter { $0.classId == classInfo?.classId }.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath)
        let classRooms = classDataManager.classList.filter { $0.classId == classInfo?.classId }.map { $0.room }
        cell.textLabel?.text = classRooms[indexPath.row]
        return cell
    }

    private func setupEditButton() {
        guard classInfo?.classIdChangeable == true else { return } // classIdChangeableがtrueの場合にのみ編集ボタンを表示

        editButton.setTitle("編集", for: .normal)
        editButton.backgroundColor = .blue
        editButton.layer.cornerRadius = 5
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.addTarget(self, action: #selector(editClassInfo), for: .touchUpInside)
        contentView.addSubview(editButton)

        NSLayoutConstraint.activate([
            editButton.bottomAnchor.constraint(equalTo: urlButton.topAnchor, constant: 45),
            editButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -25),
            editButton.widthAnchor.constraint(equalToConstant: 100),
            editButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.widthAnchor.constraint(equalToConstant: 300),
            contentView.heightAnchor.constraint(equalToConstant: 620),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),
            
            classNameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            classNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            classNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            professorNameLabel.topAnchor.constraint(equalTo: classNameLabel.bottomAnchor, constant: 20),
            professorNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            professorNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            tableView.topAnchor.constraint(equalTo: professorNameLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tableView.heightAnchor.constraint(equalToConstant: 100), // 高さを調整
            
            alarmSwitch.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 20),
            alarmSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            collectionView.topAnchor.constraint(equalTo: alarmSwitch.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            collectionViewHeightConstraint,
            /*
            closeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
            closeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalToConstant: 50),
            closeButton.heightAnchor.constraint(equalToConstant: 50),
            */
            urlButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
            urlButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            urlButton.widthAnchor.constraint(equalToConstant: 100),
            urlButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    private var collectionViewHeightConstraint: NSLayoutConstraint!

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.backgroundColor = .white
        
        //セルのクリックを反応させるための試行錯誤
        collectionView.isUserInteractionEnabled = true
        collectionView.allowsSelection = true
        
        //collectionView.backgroundColor = .red // 一時的に背景色を設定
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(collectionView)
        
        collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 260) // 初期高さを設定
        collectionViewHeightConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: alarmSwitch.bottomAnchor, constant: 20), // スイッチの下に配置
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }

    private let toggleButton = UIButton()

    private func setupToggleButton() {
        toggleButton.setTitle("🔽", for: .normal)
        toggleButton.addTarget(self, action: #selector(toggleCollectionView), for: .touchUpInside)
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(toggleButton)
        
        NSLayoutConstraint.activate([
            toggleButton.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: -30), // 固定位置
            toggleButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10), // 固定位置
            toggleButton.widthAnchor.constraint(equalToConstant: 30),
            toggleButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    @objc private func toggleCollectionView() {
        let isExpanded = collectionViewHeightConstraint.constant > 0
        collectionViewHeightConstraint.constant = isExpanded ? 0 : 260
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func setupAlarmSwitch() {
        // 既存の情報からスイッチの状態を設定
        alarmSwitch.isOn = classInfo?.isNotifying ?? false
    }
    
    @objc private func alarmSwitchChanged() {
        print("通知スイッチが変更されました")
        // スイッチの状態が変わった時の処理
        classInfo?.isNotifying = alarmSwitch.isOn
        
        // CoreDataの更新
        updateCoreDataNotificationStatus()
        
        // 通知の削除
        if alarmSwitch.isOn == false {
            removeNotification(for: classInfo?.name)
        }
        
        // 必要ならデリゲートや通知を通じて変更を通知
        if let updatedClassInfo = classInfo {
            delegate?.classInfoDidUpdate(updatedClassInfo)
        }
    }

    private func updateCoreDataNotificationStatus() {
        //print("今から通知のオンオフを保存します")
        guard let context = managedObjectContext, let classInfo = classInfo else { return }
        print("今から通知のオンオフを保存します")
        // classInfo の中身を確認
        print("ClassInfo - dayAndPeriod: \(classInfo.dayAndPeriod), isNotifying: \(classInfo.isNotifying), その他の情報: \(classInfo)")
        // フェッチリクエストを作成して該当のクラス情報を取得
        let fetchRequest: NSFetchRequest<MyClassDataStore> = MyClassDataStore.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "classId == %lld", classInfo.classId)

        do {
            let results = try context.fetch(fetchRequest)
            if let myClassData = results.first {
                myClassData.isNotifying = classInfo.isNotifying
                
                // 変更を保存
                try context.save()
                print("isNotifying保存したよ")
                printCoreDataClassData()
            }
        } catch {
            print("Failed to update CoreData: \(error)")
        }
    }
    
    private func removeNotification(for className: String?) {
        guard let className = className else { return }
        
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let identifiersToRemove = requests.filter { $0.content.title == className }.map { $0.identifier }
            
            center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            print("通知を削除しました: \(identifiersToRemove)")
            
            // 削除後の通知リストを表示して確認
            self.printPendingNotifications()
        }
    }
    
    private func printPendingNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            print("Pending notifications after deletion:")
            for request in requests {
                print("Notification ID: \(request.identifier), Title: \(request.content.title)")
            }
        }
        center.getDeliveredNotifications { notifications in
            print("Delivered notifications after deletion:")
            for notification in notifications {
                print("Notification ID: \(notification.request.identifier), Title: \(notification.request.content.title)")
            }
        }
    }
    
    func getRoomInfo(from dayAndPeriod: Int) -> String {
        let days = ["月", "火", "水", "木", "金", "土", "日"]
        let period = dayAndPeriod / 7 + 1
        let dayIndex = dayAndPeriod % 7
        let day = days[dayIndex]
        return "\(day)\(period):教室名"
    }
    
    func printCoreDataClassData() {
        let fetchRequest: NSFetchRequest<MyClassDataStore> = MyClassDataStore.fetchRequest()
        
        do {
            let classes = try managedObjectContext?.fetch(fetchRequest) ?? []
            for classData in classes {
                print("CoreData Class ID: \(classData.dayAndPeriod)")
                print("CoreData Class Title: \(classData.classTitle ?? "")")
                //print("CoreData Class Room: \(classData.classRoom ?? "")")
                //print("CoreData Professor Name: \(classData.professorName ?? "")")
                //print("CoreData Class URL: \(classData.classURL ?? "")")
                print("CoreData Class ID Changeable: \(classData.classIdChangeable)")
                print("CoreData Is Notifying: \(classData.isNotifying)")
            }
        } catch {
            print("Failed to fetch classes from CoreData: \(error)")
        }
    }
    
    @objc private func editClassInfo() {
        // 編集用のアラートダイアログを表示
        let alertController = UIAlertController(title: "授業情報の編集", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = self.classInfo?.room
            textField.placeholder = "場所"
        }
        alertController.addTextField { textField in
            textField.text = "" // 時間(ID)を直接編集するのではなく、例えば「月1」といった形式で入力を受け付ける
            textField.placeholder = "時間（例：月2）"
        }

        let saveAction = UIAlertAction(title: "保存", style: .default) { _ in
            let roomText = alertController.textFields?.first?.text ?? ""
            let timeText = alertController.textFields?.last?.text ?? ""

            // ここでclassInfoを更新する処理を記述
            self.classInfo?.room = roomText
            
            // 時間(ID)の更新処理
            let timeId = self.convertTimeToId(time: timeText)
            // この例ではclassInfoに直接IDを保存するプロパティがあると仮定しています
            // 実際のプロパティ名に合わせてください
            self.classInfo?.dayAndPeriod = timeId
            
            // 更新後の情報でUIを更新する処理をここに追加
            self.updateUIWithClassInfo()
            
            // 更新されたclassInfoの内容をログに出力
            if let updatedClassInfo = self.classInfo {
                print("更新された授業情報：")
                print("ID: \(updatedClassInfo.dayAndPeriod), 教室: \(updatedClassInfo.room)")
                // ここでデリゲートメソッドを呼び出し
                self.delegate?.classInfoDidUpdate(updatedClassInfo)
            }
        }

        alertController.addAction(saveAction)
        alertController.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
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

    private func updateUIWithClassInfo() {
        if let classInfo = classInfo {
            classNameLabel.text = "教科名\n\(classInfo.name)"
            classRoomLabel.text = "時間・教室\n\(classInfo.room)"
            professorNameLabel.text = "担当教授名\n\(classInfo.professorName)"
            alarmSwitch.isOn = classInfo.isNotifying  // スイッチの状態を更新
            // その他のUI要素があればここで更新
        }
    }

    @objc private func closePopup() {
        delegate?.classInfoPopupDidClose()
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func openURL() {
        // ベースURL
        let baseURLString = "https://ct.ritsumei.ac.jp/ct/"
        // classInfoから取得したURLパス
        if let urlPath = classInfo?.url, let url = URL(string: baseURLString + urlPath) {
            UIApplication.shared.open(url)
        }
    }
 
    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 8 * 8 // 8x8 のセル数
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)

        // ラベルが既に存在する場合は削除
        for subview in cell.contentView.subviews {
            subview.removeFromSuperview()
        }

        let label = UILabel(frame: cell.contentView.bounds)
        label.textAlignment = .center

        // 1行目に曜日を表示
        if indexPath.item >= 1 && indexPath.item <= 7 {
            let weekdays = ["月", "火", "水", "木", "金", "土", "日"]
            label.text = weekdays[indexPath.item - 1]
        }
        // 1列目に数字を表示
        else if indexPath.item % 8 == 0 && indexPath.item != 0 {
            let rowNumber = indexPath.item / 8
            label.text = "\(rowNumber)"
        }

        // 授業が存在する場合は緑色に変更
        if let classDataManager = classDataManager {
            for classData in classDataManager.classList {
                let row = classData.dayAndPeriod / 7 + 1
                let column = classData.dayAndPeriod % 7 + 1
                let itemIndex = row * 8 + column
                
                if indexPath.item == itemIndex {
                    cell.backgroundColor = .green
                    break
                }
            }
        }

        cell.contentView.addSubview(label)
        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let side = (collectionView.bounds.width - (7 * 1)) / 8 // セルの幅を計算
        return CGSize(width: side, height: side)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 1行目、1列目、緑のセルをクリックした場合は何もしない
        print("didSelectItemAtが呼び出されました。")
        if indexPath.item <= 7 || indexPath.item % 8 == 0 {
            return
        }
        /*
        if let cell = collectionView.cellForItem(at: indexPath), cell.backgroundColor == .green {
            return
        }
         */
        // セルが緑であってもclassIdChangeableがtrueの場合はデータを削除する
        if let cell = collectionView.cellForItem(at: indexPath), cell.backgroundColor == .green {
            // 対応するデータを取得
            let row = indexPath.item / 8
            let column = indexPath.item % 8
            let dayAndPeriod = (row - 1) * 7 + (column - 1)
            
            // 該当するデータを検索
            if let index = classDataManager.classList.firstIndex(where: { $0.dayAndPeriod == dayAndPeriod && $0.classIdChangeable }) {
                // データを削除
                classDataManager.classList.remove(at: index)
                print("dayAndPeriodが\(dayAndPeriod)のデータが削除されました")
                // classDataManager.classListをソート
                classDataManager.classList.sort(by: { $0.dayAndPeriod < $1.dayAndPeriod })
                collectionView.reloadData()
                // CoreDataに反映
                classDataManager.deleteClassDataFromDB(dayAndPeriod: dayAndPeriod)
                return
            }
        }

        // クリックされたセルの新しいdayAndPeriodを計算
        let row = indexPath.item / 8
        let column = indexPath.item % 8
        let newDayAndPeriod = (row - 1) * 7 + (column - 1)
        print("新たなdayAndPeriod:\(newDayAndPeriod)")

        // 複製するデータを選択
        guard let classInfo = classInfo else { return }
        let roomInfo = getRoomInfo(from: newDayAndPeriod)
        let newClassData = ClassData(
            classId: classInfo.classId, // 識別子は新しいクラスデータを作る際には変更する必要があるかもしれません
            dayAndPeriod: newDayAndPeriod,
            name: classInfo.name,
            room: roomInfo,
            url: classInfo.url,
            professorName: classInfo.professorName,
            classIdChangeable: classInfo.classIdChangeable,
            isNotifying: classInfo.isNotifying
        )

        // classDataManager.classListに追加
        classDataManager.classList.append(newClassData)
        // classDataManager.classListをソート
        classDataManager.classList.sort(by: { $0.dayAndPeriod < $1.dayAndPeriod })
        collectionView.reloadData()
        // CoreDataに反映
        classDataManager.replaceClassDataIntoDB(classInformationList: classDataManager.classList)
    }
}
