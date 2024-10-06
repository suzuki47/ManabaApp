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

class ClassInfoPopupViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    weak var delegate: ClassInfoPopupDelegate?
    var classInfo: ClassData?
    var classDataManager: ClassDataManager!
    private var tableView: UITableView!
    private let contentView = UIView()
    private let titleLabel = UILabel()
    //private let classNameLabel = UILabel()
    //private let classRoomLabel = UILabel()
    //private let professorNameLabel = UILabel()
    private let urlButton = UIButton()
    //private let editButton = UIButton()
    private let saveButton = UIButton()
    private let cancelButton = UIButton()
    private var collectionView: UICollectionView!
    private var tableViewHeightConstraint: NSLayoutConstraint!
    private var contentViewHeightConstraint: NSLayoutConstraint!
    
    // 新しいタイトルラベルの追加
    private let classNameTitleLabel = UILabel()
    private let classRoomTitleLabel = UILabel()
    private let professorNameTitleLabel = UILabel()

    // 内容を表示するラベルをリネーム（枠線を囲む部分）
    private let classNameContentLabel = UILabel()
    private let professorNameContentLabel = UILabel()
    
    let graduationCapImageView = UIImageView()
    let diamondImageView = UIImageView()
    let personImageView = UIImageView()
    
    // アイコンのサイズ調整用の変数
    let iconSize: CGFloat = 20 // お好みで調整してください
    // ラベルのサイズを統一
    let labelWidth: CGFloat = 270 // お好みの幅に調整してください
    let labelHeight: CGFloat = 40 // お好みの高さに調整してください
    
    //private var isCollectionViewExpanded = false
    private var isCollectionViewExpanded = true
    
    // CoreDataのコンテキスト
    var managedObjectContext: NSManagedObjectContext?
    
    private var pendingClassListChanges: [ClassData] = []
    private var pendingDeletions: [Int] = [] // 削除予定の dayAndPeriod のリスト
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //setupLayout()
    
        // タップジェスチャをビューに追加
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // CoreDataのコンテキストを取得
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            managedObjectContext = appDelegate.persistentContainer.viewContext
        }
        // 初期化
        pendingClassListChanges = classDataManager.classList.map { $0.copy() as! ClassData }
        
        // 初期状態でcollectionViewを閉じる
        isCollectionViewExpanded = false
        
        // 条件に基づいてcollectionViewを展開する
        if !classDataManager.classesToRegister.isEmpty {
            isCollectionViewExpanded = true
        }
        setupLayout()
        collectionViewHeightConstraint.constant = isCollectionViewExpanded ? 260 : 0
        
        collectionView.delegate = self
        collectionView.dataSource = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
    }
    
    @objc private func viewTapped(gesture: UITapGestureRecognizer) {
        // タップされた位置を取得
        let location = gesture.location(in: view)
        
        // タップされた位置がcontentViewの外側であるか判定
        if !contentView.frame.contains(location) {
            // キャンセル・保存ボタンが非表示の場合のみポップアップを閉じる
            if saveButton.isHidden && cancelButton.isHidden {
                closePopup()
            }
        }
    }
    
    private func setupLayout() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 12
        contentView.layer.borderColor = UIColor.black.cgColor // 枠線の色を黒に設定
        contentView.layer.borderWidth = 1.0 // 枠線の幅を設定
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentViewHeightConstraint = contentView.heightAnchor.constraint(equalToConstant: 700)
        contentViewHeightConstraint.isActive = true
        view.addSubview(contentView)
        
        let titleText = "選択した授業"
        let titleAttributedString = NSMutableAttributedString(string: titleText)
        titleAttributedString.addAttributes([.font: UIFont.boldSystemFont(ofSize: titleLabel.font.pointSize)], range: NSRange(location: 0, length: titleText.count))
        titleLabel.attributedText = titleAttributedString
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        saveButton.setTitle("保存", for: .normal)
        saveButton.backgroundColor = .clear // 背景色をクリアに設定
        saveButton.layer.cornerRadius = 0 // 角の丸みを取り除く
        saveButton.layer.borderWidth = 0 // 枠線を取り除く
        saveButton.setTitleColor(UIColor(red: 0/255, green: 153/255, blue: 15/255, alpha: 1.0), for: .normal)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        saveButton.isHidden = true
        contentView.addSubview(saveButton)
        
        cancelButton.setTitle("キャンセル", for: .normal)
        cancelButton.backgroundColor = .clear // 背景色をクリアに設定
        cancelButton.layer.cornerRadius = 0 // 角の丸みを取り除く
        cancelButton.layer.borderWidth = 0 // 枠線を取り除く
        cancelButton.setTitleColor(UIColor(red: 96/255, green: 96/255, blue: 96/255, alpha: 1.0), for: .normal)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.isHidden = true
        contentView.addSubview(cancelButton)

        // 教科名タイトルラベルの設定
        classNameTitleLabel.text = " 教科名"
        classNameTitleLabel.font = UIFont.systemFont(ofSize: 16)
        classNameTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(classNameTitleLabel)
        
        // 🎓アイコンの設定
        graduationCapImageView.image = UIImage(named: "graduation_cap") // アイコン画像を設定
        graduationCapImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(graduationCapImageView)
        
        // 教科名内容ラベルの設定（枠線を追加）
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
        
        // 教授名タイトルラベルの設定
        professorNameTitleLabel.text = " 教授名"
        professorNameTitleLabel.font = UIFont.systemFont(ofSize: 16)
        professorNameTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(professorNameTitleLabel)
        
        // 👤アイコンの設定
        personImageView.image = UIImage(named: "person_icon") // アイコン画像を設定
        personImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(personImageView)
        
        // 教授名内容ラベルの設定（枠線を追加）
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
        
        // 時間・教室・通知切替タイトルラベルの設定
        classRoomTitleLabel.text = " 時間・教室・通知切替"
        classRoomTitleLabel.font = UIFont.systemFont(ofSize: 16)
        classRoomTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(classRoomTitleLabel)
        
        // 🔶アイコンの設定
        diamondImageView.image = UIImage(named: "diamond_icon") // アイコン画像を設定
        diamondImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(diamondImageView)
        
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
        
        setupTableView()
        setupCollectionView()
        setupToggleButton()
        
        setupConstraints()
    }
   
    private func setupTableView() {
        tableView = UITableView()
        tableView.register(EditableTableViewCell.self, forCellReuseIdentifier: "EditableTableViewCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tableView)
        
        tableView.separatorColor = .black
        
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 100)
    }
    
    func updateContentViewHeight(rowCount: Int) {
        let baseHeight: CGFloat = 566 // セルが0の場合の高さ
        let additionalHeight: CGFloat = 48 // セルが1つ増えるごとの追加高さ
        var newHeight = baseHeight + CGFloat(rowCount) * additionalHeight
        if !isCollectionViewExpanded {
            newHeight = newHeight - 260
        }
        contentViewHeightConstraint.constant = newHeight

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    // テーブルビューの高さを更新
    func updateTableViewHeight(rowCount: Int) {
        let cellHeight: CGFloat = 40 // セルの高さ
        let footerHeight: CGFloat = 4 // セル間のスペース
        let tableViewHeight = CGFloat(rowCount) * (cellHeight + footerHeight)
        tableViewHeightConstraint.constant = tableViewHeight

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }

        updateContentViewHeight(rowCount: rowCount)
    }
    
    // MARK: - UITableViewDataSource

    // セルの設定
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "EditableTableViewCell", for: indexPath) as! EditableTableViewCell
        let filteredClassData = classDataManager.classList.filter { $0.classId == classInfo?.classId }
        
        // データを安全に取得
        if indexPath.section < filteredClassData.count {
            let classData = filteredClassData[indexPath.section]
            
            // 表示テキストをそのままセット
            cell.textField.text = classData.room
            
            // 編集開始位置を ":" の後に設定
            if let colonRange = classData.room.range(of: ":") {
                let startPosition = cell.textField.position(from: cell.textField.beginningOfDocument, offset: classData.room.distance(from: classData.room.startIndex, to: colonRange.upperBound))
                cell.textField.selectedTextRange = cell.textField.textRange(from: startPosition!, to: cell.textField.endOfDocument)
            }
            
            cell.textField.tag = indexPath.section
            cell.textField.delegate = self
            
            let switchView = UISwitch(frame: .zero)
            switchView.isOn = classData.isNotifying
            switchView.tag = indexPath.section
            switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            cell.accessoryView = switchView
        }

        return cell
    }

    // セクション数をデータの数に設定
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let classDataManager = classDataManager, let classInfo = classInfo else {
            return 0
        }
        let sectionCount = classDataManager.classList.filter { $0.classId == classInfo.classId }.count
        updateTableViewHeight(rowCount: sectionCount)
        print("セクション数：\(sectionCount)")
        return sectionCount
    }

    // 各セクションに1つのセルを設定
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    // セルの高さを設定
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40 // お好みの高さに調整
    }

    // セクションのフッターの高さを設定（セル間のスペース）
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 4 // セル間のスペース
    }

    // フッターのビューを返す
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = UIColor.clear // 背景色を透明に設定
        return footerView
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text, let colonRange = text.range(of: ":") else {
            return true
        }
        
        // ":" の後の部分の範囲を計算
        let colonPosition = text.distance(from: text.startIndex, to: colonRange.upperBound)
        
        // 編集範囲が ":" の後ろであれば編集可能
        if range.location >= colonPosition {
            // 編集があったのでボタンを表示
            showButtonsIfNeeded()
            return true
        } else {
            // ":" 以前は編集不可
            return false
        }
    }

    @objc private func switchChanged(_ sender: UISwitch) {
        let classData = classDataManager.classList.filter { $0.classId == classInfo?.classId }[sender.tag]
        classData.isNotifying = sender.isOn
        
        //TODO: CoreDataの更新
        updateCoreDataNotificationStatus(for: classData)
        
        if !sender.isOn {
            removeNotification(for: classData.name)
        }
        
        // デリゲートに変更を通知
        delegate?.classInfoDidUpdate(classData)
    }
    
    private func updateCoreDataClassRoom(for classData: ClassData) {
        guard let context = managedObjectContext else { return }
        
        let fetchRequest: NSFetchRequest<MyClassDataStore> = MyClassDataStore.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "classId == %lld AND dayAndPeriod == %d", classData.classId, classData.dayAndPeriod)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let myClassData = results.first {
                myClassData.classRoom = classData.room
                print(classData.dayAndPeriod)
                print(classData.room)
                
                try context.save()
                print("Class roomを保存しました")
            }
        } catch {
            print("Failed to update CoreData: \(error)")
        }
    }
    
    @objc private func cancelButtonTapped() {
        print("キャンセルボタンが押されました")
        closePopup()
        // ボタンを隠す
        saveButton.isHidden = true
        cancelButton.isHidden = true
    }
    
    private func showButtonsIfNeeded() {
        if !saveButton.isHidden && !cancelButton.isHidden {
            return
        }
        
        saveButton.isHidden = false
        cancelButton.isHidden = false
        
        // 変更があったことを反映するためにレイアウトを更新
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.widthAnchor.constraint(equalToConstant: 300),
            contentViewHeightConstraint, // 高さ制約を適用
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor), // 中央揃え
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            saveButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveButton.widthAnchor.constraint(equalToConstant: 50),
            saveButton.heightAnchor.constraint(equalToConstant: 30),
            
            cancelButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -200),
            cancelButton.widthAnchor.constraint(equalToConstant: 100),
            cancelButton.heightAnchor.constraint(equalToConstant: 30),
            
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
            
            tableView.topAnchor.constraint(equalTo: classRoomTitleLabel.bottomAnchor, constant: 5),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tableViewHeightConstraint,
            
            collectionView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            collectionViewHeightConstraint,
            
            // 教授名タイトルラベルとアイコンの制約
            personImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            personImageView.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 16),
            personImageView.widthAnchor.constraint(equalToConstant: iconSize),
            personImageView.heightAnchor.constraint(equalToConstant: iconSize),

            professorNameTitleLabel.leadingAnchor.constraint(equalTo: personImageView.trailingAnchor, constant: 8),
            professorNameTitleLabel.centerYAnchor.constraint(equalTo: personImageView.centerYAnchor),

            // 教授名内容ラベルの制約
            professorNameContentLabel.topAnchor.constraint(equalTo: professorNameTitleLabel.bottomAnchor, constant: 8),
            professorNameContentLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            professorNameContentLabel.widthAnchor.constraint(equalToConstant: labelWidth),
            professorNameContentLabel.heightAnchor.constraint(equalToConstant: labelHeight),
            
            urlButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            urlButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            urlButton.widthAnchor.constraint(equalToConstant: 130),
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
            collectionView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }

    private let toggleButton = UIButton()

    private func setupToggleButton() {
        toggleButton.setTitle(isCollectionViewExpanded ? "▼ 時間割表" : "▶︎ 時間割表", for: .normal)
        toggleButton.setTitleColor(.black, for: .normal)
        toggleButton.addTarget(self, action: #selector(toggleCollectionView), for: .touchUpInside)
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(toggleButton)
        
        NSLayoutConstraint.activate([
            toggleButton.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: -25), // 固定位置
            toggleButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -125), // 固定位置
            toggleButton.widthAnchor.constraint(equalToConstant: 200),
            toggleButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    @objc private func toggleCollectionView() {
        isCollectionViewExpanded.toggle() // フラグを反転させる
        collectionViewHeightConstraint.constant = isCollectionViewExpanded ? 260 : 0
        toggleButton.setTitle(isCollectionViewExpanded ? "▼ 時間割表" : "▶︎ 時間割表", for: .normal)

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        let sectionCount = classDataManager.classList.filter { $0.classId == classInfo?.classId }.count
        updateContentViewHeight(rowCount: sectionCount)
    }

    private func updateCoreDataNotificationStatus(for classData: ClassData) {
        guard let context = managedObjectContext else { return }
        
        let fetchRequest: NSFetchRequest<MyClassDataStore> = MyClassDataStore.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "classId == %lld", classData.classId)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let myClassData = results.first {
                myClassData.isNotifying = classData.isNotifying
                
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
                print("CoreData Class ID Changeable: \(classData.classIdChangeable)")
                print("CoreData Is Notifying: \(classData.isNotifying)")
            }
        } catch {
            print("Failed to fetch classes from CoreData: \(error)")
        }
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
        cell.backgroundColor = .white
        cell.layer.borderColor = UIColor.black.cgColor // 枠線の色
        cell.layer.borderWidth = 1.0 // 枠線の幅

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
        if let classDataManager = classDataManager, let classInfo = classInfo {
            for classData in pendingClassListChanges {
                let row = classData.dayAndPeriod / 7 + 1
                let column = classData.dayAndPeriod % 7 + 1
                let itemIndex = row * 8 + column
                
                if indexPath.item == itemIndex {
                    if classData.classId == classInfo.classId {
                        cell.backgroundColor = .green
                    } else {
                        cell.backgroundColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0) // 濃い灰色
                    }
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
        print("didSelectItemAtが呼び出されました。")
        if indexPath.item <= 7 || indexPath.item % 8 == 0 {
            return
        }
        
        if let cell = collectionView.cellForItem(at: indexPath), cell.backgroundColor == .green {
            let row = indexPath.item / 8
            let column = indexPath.item % 8
            let dayAndPeriod = (row - 1) * 7 + (column - 1)
            
            if let index = pendingClassListChanges.firstIndex(where: { $0.dayAndPeriod == dayAndPeriod && $0.classIdChangeable }) {
                pendingClassListChanges.remove(at: index)
                pendingDeletions.append(dayAndPeriod) // 削除を保留
                print("dayAndPeriodが\(dayAndPeriod)のデータが削除予定に追加されました")
                classDataManager.classList.sort(by: { $0.dayAndPeriod < $1.dayAndPeriod })
                
                print("dayAndPeriodが\(dayAndPeriod)のデータがpendingClassListChangesから削除されました")
                collectionView.reloadData()
                tableView.reloadData()
                // 変更があったのでボタンを表示
                showButtonsIfNeeded()
                return
            }
        }
        
        let row = indexPath.item / 8
        let column = indexPath.item % 8
        let newDayAndPeriod = (row - 1) * 7 + (column - 1)
        print("新たなdayAndPeriod:\(newDayAndPeriod)")

        guard let classInfo = classInfo else { return }
        let roomInfo = getRoomInfo(from: newDayAndPeriod)
        let newClassData = ClassData(
            classId: classInfo.classId,
            dayAndPeriod: newDayAndPeriod,
            name: classInfo.name,
            room: roomInfo,
            url: classInfo.url,
            professorName: classInfo.professorName,
            classIdChangeable: classInfo.classIdChangeable,
            isNotifying: classInfo.isNotifying
        ).copy() // ディープコピーを作成
        
        pendingClassListChanges.append(newClassData)
        pendingClassListChanges.sort(by: { $0.dayAndPeriod < $1.dayAndPeriod })
        collectionView.reloadData()
        tableView.reloadData()
        
        // 変更があったのでボタンを表示
        showButtonsIfNeeded()
    }

    @objc private func saveButtonTapped() {
        guard let visibleCells = tableView.visibleCells as? [EditableTableViewCell] else { return }
        
        for cell in visibleCells {
            if let indexPath = tableView.indexPath(for: cell) {
                let filteredClassData = pendingClassListChanges.filter { $0.classId == classInfo?.classId }
                
                // 配列が空でないことと、indexPath.rowが範囲内であることを確認
                if indexPath.row < filteredClassData.count {
                    let classData = filteredClassData[indexPath.row]
                    
                    if let text = cell.textField.text, let colonRange = text.range(of: ":") {
                        let prefixText = String(text[..<colonRange.upperBound])
                        let editedRoomName = String(text[colonRange.upperBound...])
                        classData.room = prefixText + editedRoomName
                    } else {
                        classData.room = cell.textField.text ?? ""
                    }
                } else {
                    print("Error: Index out of range or no matching data for the given classId")
                }
            }
        }
        // 削除予定のデータを適用
        for dayAndPeriod in pendingDeletions {
            if let index = classDataManager.classList.firstIndex(where: { $0.dayAndPeriod == dayAndPeriod }) {
                classDataManager.classList.remove(at: index)
                classDataManager.deleteClassDataFromDB(dayAndPeriod: dayAndPeriod)
            }
        }
        
        classDataManager.classList = pendingClassListChanges.map { $0.copy() as! ClassData }
        classDataManager.replaceClassDataIntoDB(classInformationList: classDataManager.classList)
        
        if let updatedClassInfo = classInfo {
            delegate?.classInfoDidUpdate(updatedClassInfo)
        }
        collectionView.reloadData()
        tableView.reloadData()
        
        // ボタンを隠す
        saveButton.isHidden = true
        cancelButton.isHidden = true
        
        closePopup()
    }
}
