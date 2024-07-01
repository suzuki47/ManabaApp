//
//  ClassInfoPopupViewController.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2024/03/07.
//

import UIKit
import CoreData

protocol ClassInfoPopupDelegate: AnyObject {
    func classInfoDidUpdate(_ updatedClassInfo: ClassInformation)
}

class ClassInfoPopupViewController: UIViewController {
    weak var delegate: ClassInfoPopupDelegate?
    var classInfo: ClassInformation?
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let classNameLabel = UILabel()
    private let classRoomLabel = UILabel()
    private let professorNameLabel = UILabel()
    private let closeButton = UIButton()
    private let urlButton = UIButton()
    private let editButton = UIButton()
    private let alarmSwitch = UISwitch()
    
    // CoreDataのコンテキスト
    var managedObjectContext: NSManagedObjectContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupEditButton()
        setupAlarmSwitch()  // スイッチのレイアウト設定
        
        // タップジェスチャをビューに追加
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        view.addGestureRecognizer(tapGesture)
        
        // CoreDataのコンテキストを取得
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            managedObjectContext = appDelegate.persistentContainer.viewContext
        }
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

        // コンテンツビューの設定
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 12
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)

        // タイトルラベルの設定
        titleLabel.text = "選択した授業"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        // 教科名ラベルの設定
        classNameLabel.text = "教科名\n\(classInfo?.name ?? "")"
        classNameLabel.numberOfLines = 0
        classNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(classNameLabel)

        // 時間・教室ラベルの設定
        classRoomLabel.text = "時間・教室\n\(classInfo?.room ?? "")"
        classRoomLabel.numberOfLines = 0
        classRoomLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(classRoomLabel)
        
        // 教授名ラベルの設定
        professorNameLabel.text = "担当教授名\n\(classInfo?.professorName ?? "")"
        professorNameLabel.numberOfLines = 0
        professorNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(professorNameLabel)

        // 閉じるボタンの設定
        closeButton.setTitle("×", for: .normal)
        closeButton.backgroundColor = .lightGray
        closeButton.layer.cornerRadius = 5
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closePopup), for: .touchUpInside)
        contentView.addSubview(closeButton)

        // URLボタンの設定
        urlButton.setTitle("授業ページ", for: .normal)
        urlButton.backgroundColor = .lightGray
        urlButton.layer.cornerRadius = 5
        urlButton.translatesAutoresizingMaskIntoConstraints = false
        urlButton.addTarget(self, action: #selector(openURL), for: .touchUpInside)
        contentView.addSubview(urlButton)

        // スイッチの追加
        alarmSwitch.translatesAutoresizingMaskIntoConstraints = false
        alarmSwitch.addTarget(self, action: #selector(alarmSwitchChanged), for: .valueChanged)
        contentView.addSubview(alarmSwitch)
        
        // Auto Layoutの設定
        setupConstraints()
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
            editButton.bottomAnchor.constraint(equalTo: closeButton.topAnchor, constant: -20),
            editButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            editButton.widthAnchor.constraint(equalToConstant: 100),
            editButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.widthAnchor.constraint(equalToConstant: 300),
            contentView.heightAnchor.constraint(equalToConstant: 300), // 高さを調整
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            classNameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            classNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            classNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            classRoomLabel.topAnchor.constraint(equalTo: classNameLabel.bottomAnchor, constant: 20),
            classRoomLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            classRoomLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            professorNameLabel.topAnchor.constraint(equalTo: classRoomLabel.bottomAnchor, constant: 20),
            professorNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            professorNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            closeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            closeButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 50),
            closeButton.heightAnchor.constraint(equalToConstant: 50),
            
            // URLボタンを右下に配置するように調整
            urlButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            urlButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            urlButton.widthAnchor.constraint(equalToConstant: 100),
            urlButton.heightAnchor.constraint(equalToConstant: 50),

            // スイッチの配置
            alarmSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            alarmSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
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
            self.classInfo?.dayAndPeriod = String(timeId)
            
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
}
