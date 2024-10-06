//
//  UnChangeableClassInfoPopupViewController.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2024/07/15.
//

import UIKit
import CoreData
/*
protocol ClassInfoPopupDelegate: AnyObject {
    func classInfoDidUpdate(_ updatedClassInfo: ClassData)
}
 */

class UnChangeableClassInfoPopupViewController: UIViewController {
    weak var delegate: ClassInfoPopupDelegate?
    var classInfo: ClassData?
    var classDataManager: ClassDataManager!
    private let contentView = UIView()
    private let titleLabel = UILabel()
    // 新しいタイトルラベルの追加
    private let classNameTitleLabel = UILabel()
    private let classRoomTitleLabel = UILabel()
    private let professorNameTitleLabel = UILabel()

    // 内容を表示するラベルをリネーム（枠線を囲む部分）
    private let classNameContentLabel = UILabel()
    private let classRoomContentLabel = UILabel()
    private let professorNameContentLabel = UILabel()
    private let urlButton = UIButton()
    //private let editButton = UIButton()
    private let alarmSwitch = UISwitch()
    
    
    // CoreDataのコンテキスト
    var managedObjectContext: NSManagedObjectContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        //setupEditButton()
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
        contentView.layer.borderColor = UIColor.black.cgColor // 枠線の色を黒に設定
        contentView.layer.borderWidth = 1.0 // 枠線の幅を設定
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        
        // タイトルラベルの設定
        let titleText = "選択した授業"
        let titleAttributedString = NSMutableAttributedString(string: titleText)
        titleAttributedString.addAttributes([.font: UIFont.boldSystemFont(ofSize: titleLabel.font.pointSize)], range: NSRange(location: 0, length: titleText.count))
        titleLabel.attributedText = titleAttributedString
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // アイコンのサイズ調整用の変数
        let iconSize: CGFloat = 20 // お好みで調整してください

        // 教科名タイトルラベルの設定
        let classNameTitleLabel = UILabel()
        classNameTitleLabel.text = " 教科名"
        classNameTitleLabel.font = UIFont.systemFont(ofSize: 16)
        classNameTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(classNameTitleLabel)
        
        // 🎓アイコンの設定
        let graduationCapImageView = UIImageView()
        graduationCapImageView.image = UIImage(named: "graduation_cap") // アイコン画像を設定
        graduationCapImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(graduationCapImageView)
        
        // 教科名内容ラベルの設定（枠線を追加）
        let classNameContentLabel = UILabel()
        let classInfoName = classInfo?.name ?? ""
        let pattern = "\\d{5}:"
        let truncatedClassInfoName = classInfoName.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        
        // パラグラフスタイルを作成して左インデントを設定
        let classNameParagraphStyle = NSMutableParagraphStyle()
        classNameParagraphStyle.firstLineHeadIndent = 8.0 // インデントの値を調整できます
        
        // 属性付き文字列を作成（フォントを太字に設定）
        let classNameAttributedText = NSAttributedString(
            string: truncatedClassInfoName,
            attributes: [
                .paragraphStyle: classNameParagraphStyle,
                .font: UIFont.boldSystemFont(ofSize: 20) // 太字フォントに変更
            ]
        )
        classNameContentLabel.attributedText = classNameAttributedText
        
        classNameContentLabel.textAlignment = .left
        classNameContentLabel.backgroundColor = UIColor(red: 0x97 / 255.0, green: 0x97 / 255.0, blue: 0x97 / 255.0, alpha: 0x33 / 255.0) // 背景色をグレーに設定
        classNameContentLabel.layer.borderColor = UIColor.black.cgColor
        classNameContentLabel.layer.borderWidth = 1.0
        classNameContentLabel.layer.cornerRadius = 8
        classNameContentLabel.layer.masksToBounds = true
        classNameContentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(classNameContentLabel)
        
        // 時間・教室・通知切替タイトルラベルの設定
        let classRoomTitleLabel = UILabel()
        classRoomTitleLabel.text = " 時間・教室・通知切替"
        classRoomTitleLabel.font = UIFont.systemFont(ofSize: 16)
        classRoomTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(classRoomTitleLabel)
        
        // 🔶アイコンの設定
        let diamondImageView = UIImageView()
        diamondImageView.image = UIImage(named: "diamond_icon") // アイコン画像を設定
        diamondImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(diamondImageView)
        
        // 時間・教室内容ラベルの設定（枠線を追加）
        let classRoomContentLabel = UILabel()
        let classRoomText = classInfo?.room ?? ""
        
        // パラグラフスタイルを作成して左インデントを設定
        let classRoomParagraphStyle = NSMutableParagraphStyle()
        classRoomParagraphStyle.firstLineHeadIndent = 8.0 // インデントの値を調整できます
        
        // 属性付き文字列を作成（フォントを太字に設定）
        let classRoomAttributedText = NSAttributedString(
            string: classRoomText,
            attributes: [
                .paragraphStyle: classRoomParagraphStyle,
                .font: UIFont.boldSystemFont(ofSize: 20) // 太字フォントに変更
            ]
        )
        classRoomContentLabel.attributedText = classRoomAttributedText
        
        classRoomContentLabel.textAlignment = .left
        classRoomContentLabel.backgroundColor = UIColor(red: 0x97 / 255.0, green: 0x97 / 255.0, blue: 0x97 / 255.0, alpha: 0x33 / 255.0) // 背景色をグレーに設定
        classRoomContentLabel.layer.borderColor = UIColor.black.cgColor
        classRoomContentLabel.layer.borderWidth = 1.0
        classRoomContentLabel.layer.cornerRadius = 8
        classRoomContentLabel.layer.masksToBounds = true
        classRoomContentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(classRoomContentLabel)
        
        // 教授名タイトルラベルの設定
        let professorNameTitleLabel = UILabel()
        professorNameTitleLabel.text = " 教授名"
        professorNameTitleLabel.font = UIFont.systemFont(ofSize: 16)
        professorNameTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(professorNameTitleLabel)
        
        // 👤アイコンの設定
        let personImageView = UIImageView()
        personImageView.image = UIImage(named: "person_icon") // アイコン画像を設定
        personImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(personImageView)
        
        // 教授名内容ラベルの設定（枠線を追加）
        let professorNameContentLabel = UILabel()
        let professorNameText = classInfo?.professorName ?? ""
        
        // パラグラフスタイルを作成して左インデントを設定
        let professorNameParagraphStyle = NSMutableParagraphStyle()
        professorNameParagraphStyle.firstLineHeadIndent = 8.0 // インデントの値を調整できます
        
        // 属性付き文字列を作成（フォントを太字に設定）
        let professorNameAttributedText = NSAttributedString(
            string: professorNameText,
            attributes: [
                .paragraphStyle: professorNameParagraphStyle,
                .font: UIFont.boldSystemFont(ofSize: 20) // 太字フォントに変更
            ]
        )
        professorNameContentLabel.attributedText = professorNameAttributedText
        
        professorNameContentLabel.textAlignment = .left
        professorNameContentLabel.backgroundColor = UIColor(red: 0x97 / 255.0, green: 0x97 / 255.0, blue: 0x97 / 255.0, alpha: 0x33 / 255.0) // 背景色をグレーに設定
        professorNameContentLabel.layer.borderColor = UIColor.black.cgColor
        professorNameContentLabel.layer.borderWidth = 1.0
        professorNameContentLabel.layer.cornerRadius = 8
        professorNameContentLabel.layer.masksToBounds = true
        professorNameContentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(professorNameContentLabel)
        
        // URLボタンの設定
        urlButton.setTitle("授業ページへ→", for: .normal)
        urlButton.backgroundColor = .clear // 背景色をクリアに設定
        urlButton.layer.cornerRadius = 0 // 角の丸みを取り除く
        urlButton.layer.borderWidth = 0 // 枠線を取り除く
        urlButton.setTitleColor(.black, for: .normal) // タイトルの色を設定
        urlButton.titleLabel?.font = UIFont.systemFont(ofSize: 16) // フォントサイズを設定
        urlButton.translatesAutoresizingMaskIntoConstraints = false
        urlButton.addTarget(self, action: #selector(openURL), for: .touchUpInside)
        contentView.addSubview(urlButton)
        
        // スイッチの追加
        alarmSwitch.translatesAutoresizingMaskIntoConstraints = false
        alarmSwitch.addTarget(self, action: #selector(alarmSwitchChanged), for: .valueChanged)
        contentView.addSubview(alarmSwitch)

        // ラベルのサイズを統一
        let labelWidth: CGFloat = 270 // お好みの幅に調整してください
        let labelHeight: CGFloat = 40 // お好みの高さに調整してください

        // レイアウト制約の設定
        NSLayoutConstraint.activate([
            // contentViewの制約
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.widthAnchor.constraint(equalToConstant: 300),
            contentView.heightAnchor.constraint(equalToConstant: 350),

            // titleLabelの制約
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // 教科名タイトルラベルとアイコンの制約
            graduationCapImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            graduationCapImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            graduationCapImageView.widthAnchor.constraint(equalToConstant: iconSize),
            graduationCapImageView.heightAnchor.constraint(equalToConstant: iconSize),

            classNameTitleLabel.leadingAnchor.constraint(equalTo: graduationCapImageView.trailingAnchor, constant: 8),
            classNameTitleLabel.centerYAnchor.constraint(equalTo: graduationCapImageView.centerYAnchor),

            // 教科名内容ラベルの制約
            classNameContentLabel.topAnchor.constraint(equalTo: classNameTitleLabel.bottomAnchor, constant: 8),
            classNameContentLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            classNameContentLabel.widthAnchor.constraint(equalToConstant: labelWidth),
            classNameContentLabel.heightAnchor.constraint(equalToConstant: labelHeight),

            // 時間・教室タイトルラベルとアイコンの制約
            diamondImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            diamondImageView.topAnchor.constraint(equalTo: classNameContentLabel.bottomAnchor, constant: 16),
            diamondImageView.widthAnchor.constraint(equalToConstant: iconSize),
            diamondImageView.heightAnchor.constraint(equalToConstant: iconSize),

            classRoomTitleLabel.leadingAnchor.constraint(equalTo: diamondImageView.trailingAnchor, constant: 8),
            classRoomTitleLabel.centerYAnchor.constraint(equalTo: diamondImageView.centerYAnchor),

            // 時間・教室内容ラベルの制約
            classRoomContentLabel.topAnchor.constraint(equalTo: classRoomTitleLabel.bottomAnchor, constant: 8),
            classRoomContentLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            classRoomContentLabel.widthAnchor.constraint(equalToConstant: labelWidth),
            classRoomContentLabel.heightAnchor.constraint(equalToConstant: labelHeight),

            // 教授名タイトルラベルとアイコンの制約
            personImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            personImageView.topAnchor.constraint(equalTo: classRoomContentLabel.bottomAnchor, constant: 16),
            personImageView.widthAnchor.constraint(equalToConstant: iconSize),
            personImageView.heightAnchor.constraint(equalToConstant: iconSize),

            professorNameTitleLabel.leadingAnchor.constraint(equalTo: personImageView.trailingAnchor, constant: 8),
            professorNameTitleLabel.centerYAnchor.constraint(equalTo: personImageView.centerYAnchor),

            // 教授名内容ラベルの制約
            professorNameContentLabel.topAnchor.constraint(equalTo: professorNameTitleLabel.bottomAnchor, constant: 8),
            professorNameContentLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            professorNameContentLabel.widthAnchor.constraint(equalToConstant: labelWidth),
            professorNameContentLabel.heightAnchor.constraint(equalToConstant: labelHeight),

            // URLボタンの制約
            urlButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            urlButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            urlButton.widthAnchor.constraint(equalToConstant: 130),
            urlButton.heightAnchor.constraint(equalToConstant: 50),

            // アラームスイッチの制約
            // alarmSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            alarmSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            alarmSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 8)
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
        
        //TODO: ClassDataManagerのメソッドを使うようにする
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
    /*
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
    }*/
    
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
            // 教科名の内容ラベルを更新
            classNameContentLabel.text = classInfo.name
            
            // 教室の内容ラベルを更新
            classRoomContentLabel.text = classInfo.room
            
            // 担当教授名の内容ラベルを更新
            professorNameContentLabel.text = classInfo.professorName
            
            // スイッチの状態を更新
            alarmSwitch.isOn = classInfo.isNotifying
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
