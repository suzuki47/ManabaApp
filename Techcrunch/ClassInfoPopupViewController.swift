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
    private let classNameLabel = UILabel()
    private let classRoomLabel = UILabel()
    private let professorNameLabel = UILabel()
    private let urlButton = UIButton()
    //private let editButton = UIButton()
    private let saveButton = UIButton()
    private let cancelButton = UIButton()
    private let separatorLineBelowClassName = UIView()
    private let separatorLineBelowProfessorName = UIView()
    private var collectionView: UICollectionView!
    private var tableViewHeightConstraint: NSLayoutConstraint!
    private var contentViewHeightConstraint: NSLayoutConstraint!
    
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
        cancelButton.setTitleColor(UIColor(red: 0/255, green: 153/255, blue: 15/255, alpha: 1.0), for: .normal) 
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.isHidden = true
        contentView.addSubview(cancelButton)
        
        // 教科名ラベルの設定
        let classInfoName = classInfo?.name ?? ""
        let pattern = "\\d{5}:"
        let truncatedClassInfoName = classInfoName.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        let classNameText = " 教科名\n\(truncatedClassInfoName)"
        let classNameAttributedString = NSMutableAttributedString(string: classNameText)

        // 🎓アイコンの設定
        let graduationCapAttachment = NSTextAttachment()
        graduationCapAttachment.image = UIImage(named: "graduation_cap") // アイコン画像を設定

        // アイコンのサイズ調整
        let iconHeight = classNameLabel.font.lineHeight
        let iconRatio = graduationCapAttachment.image!.size.width / graduationCapAttachment.image!.size.height
        graduationCapAttachment.bounds = CGRect(x: 0, y: (classNameLabel.font.capHeight - iconHeight) / 2, width: iconHeight * iconRatio, height: iconHeight)

        // アイコンをNSAttributedStringに変換
        let graduationCapString = NSAttributedString(attachment: graduationCapAttachment)

        // 🎓アイコンを先頭に追加
        classNameAttributedString.insert(graduationCapString, at: 0)

        
        // ラベルに設定
        classNameLabel.attributedText = classNameAttributedString

        
        // 教科名の中央揃いスタイルを追加
        let classNameParagraphStyle = NSMutableParagraphStyle()
        classNameParagraphStyle.alignment = .center
        let classNameTextRange = (classNameText as NSString).range(of: truncatedClassInfoName)
        classNameAttributedString.addAttributes([.paragraphStyle: classNameParagraphStyle], range: classNameTextRange)
        
        classNameLabel.attributedText = classNameAttributedString
        classNameLabel.numberOfLines = 0
        classNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(classNameLabel)
        
        separatorLineBelowClassName.backgroundColor = .black
        separatorLineBelowClassName.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLineBelowClassName)
        
        // 教授名ラベルの設定
        let professorNameText = " 担当教授名\n\(classInfo?.professorName ?? "")"
        let professorNameAttributedString = NSMutableAttributedString(string: professorNameText)
        let professorNameRange = (professorNameText as NSString).range(of: "担当教授名")
        professorNameAttributedString.addAttributes([.font: UIFont.systemFont(ofSize: professorNameLabel.font.pointSize)], range: professorNameRange)
        
        // 担当教授名の中央揃いスタイルを追加
        let professorNameParagraphStyle = NSMutableParagraphStyle()
        professorNameParagraphStyle.alignment = .center
        let professorNameTextRange = (professorNameText as NSString).range(of: classInfo?.professorName ?? "")
        professorNameAttributedString.addAttributes([.paragraphStyle: professorNameParagraphStyle], range: professorNameTextRange)
        
        // 👤アイコンの設定
        let personAttachment = NSTextAttachment()
        personAttachment.image = UIImage(named: "person_icon") // アイコン画像を設定
        
        // アイコンのサイズ調整
        personAttachment.bounds = CGRect(x: 0, y: (professorNameLabel.font.capHeight - iconHeight) / 2, width: iconHeight * iconRatio, height: iconHeight)
        
        // アイコンをNSAttributedStringに変換
        let personString = NSAttributedString(attachment: personAttachment)
        
        // アイコンを先頭に追加
        professorNameAttributedString.insert(personString, at: 0)
        
        // ラベルに設定
        professorNameLabel.attributedText = professorNameAttributedString
        professorNameLabel.numberOfLines = 0
        professorNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(professorNameLabel)
        
        separatorLineBelowProfessorName.backgroundColor = .black
        separatorLineBelowProfessorName.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLineBelowProfessorName)
        
        // 時間・教室テキストの設定
        let classRoomText = " 時間・教室・通知切替"
        let classRoomAttributedString = NSMutableAttributedString(string: classRoomText)
        let classRoomRange = (classRoomText as NSString).range(of: "時間・教室・通知切替")
        classRoomAttributedString.addAttributes([.font: UIFont.systemFont(ofSize: classRoomLabel.font.pointSize)], range: classRoomRange)
        
        // diamond_iconの設定
        let diamondAttachment = NSTextAttachment()
        diamondAttachment.image = UIImage(named: "diamond_icon") // アイコン画像を設定
        
        // アイコンのサイズ調整
        diamondAttachment.bounds = CGRect(x: 0, y: (classRoomLabel.font.capHeight - iconHeight) / 2, width: iconHeight * iconRatio, height: iconHeight)
        
        // アイコンをNSAttributedStringに変換
        let diamondString = NSAttributedString(attachment: diamondAttachment)
        
        // アイコンを先頭に追加
        classRoomAttributedString.insert(diamondString, at: 0)
        
        // ラベルに設定
        classRoomLabel.attributedText = classRoomAttributedString
        classRoomLabel.numberOfLines = 0
        classRoomLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(classRoomLabel)
        
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
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: classRoomLabel.bottomAnchor, constant: 0),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tableViewHeightConstraint
        ])
    }
    
    func updateContentViewHeight(rowCount: Int) {
        let baseHeight: CGFloat = 556 // セルが0の場合の高さ
        let additionalHeight: CGFloat = 44 // セルが1つ増えるごとの追加高さ
        var newHeight = baseHeight + CGFloat(rowCount) * additionalHeight
        if !isCollectionViewExpanded {
            newHeight = newHeight - 260
        }
        contentViewHeightConstraint.constant = newHeight

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    
    func updateTableViewHeight(rowCount: Int) {
        let tableViewHeight = CGFloat(rowCount) * 44.0 // セルの高さが44の場合
        tableViewHeightConstraint.constant = tableViewHeight

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        
        updateContentViewHeight(rowCount: rowCount)
    }
    
    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let classDataManager = classDataManager, let classInfo = classInfo else {
            return 0
        }

        let rowCount = classDataManager.classList.filter { $0.classId == classInfo.classId }.count
        updateTableViewHeight(rowCount: rowCount) // TableViewの高さを更新
        return rowCount
    }
    /*
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EditableTableViewCell", for: indexPath) as! EditableTableViewCell
        let classData = classDataManager.classList.filter { $0.classId == classInfo?.classId }[indexPath.row]
        
        cell.textField.text = classData.room
        cell.textField.tag = indexPath.row
        cell.textField.delegate = self
        
        let switchView = UISwitch(frame: .zero)
        switchView.isOn = classData.isNotifying
        switchView.tag = indexPath.row
        switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        cell.accessoryView = switchView
        
        return cell
    }*/
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EditableTableViewCell", for: indexPath) as! EditableTableViewCell
        let classData = classDataManager.classList.filter { $0.classId == classInfo?.classId }[indexPath.row]
        
        // 表示テキストをそのままセット
        cell.textField.text = classData.room
        
        // 編集開始位置を ":" の後に設定
        if let colonRange = classData.room.range(of: ":") {
            let startPosition = cell.textField.position(from: cell.textField.beginningOfDocument, offset: classData.room.distance(from: classData.room.startIndex, to: colonRange.upperBound))
            cell.textField.selectedTextRange = cell.textField.textRange(from: startPosition!, to: cell.textField.endOfDocument)
        }
        
        cell.textField.tag = indexPath.row
        cell.textField.delegate = self
        
        let switchView = UISwitch(frame: .zero)
        switchView.isOn = classData.isNotifying
        switchView.tag = indexPath.row
        switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        cell.accessoryView = switchView
        
        return cell
    }

    /*func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text, let colonRange = text.range(of: ":") else {
            return true
        }
        
        // ":" の後の部分だけを編集可能にする
        let editableRange = NSRange(colonRange.upperBound..., in: text)
        return editableRange.intersection(range) != nil
    }*/

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
    /*
    @objc private func saveButtonTapped() {
        guard let visibleCells = tableView.visibleCells as? [EditableTableViewCell] else { return }
        
        for cell in visibleCells {
            if let indexPath = tableView.indexPath(for: cell) {
                let classData = classDataManager.classList.filter { $0.classId == classInfo?.classId }[indexPath.row]
                classData.room = cell.textField.text ?? ""
                
                updateCoreDataClassRoom(for: classData)
            }
        }
        
        if let updatedClassInfo = classInfo {
            delegate?.classInfoDidUpdate(updatedClassInfo)
        }
    }*/
    
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
            
            classNameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            classNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            classNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            separatorLineBelowClassName.topAnchor.constraint(equalTo: classNameLabel.bottomAnchor, constant: 10),
            separatorLineBelowClassName.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separatorLineBelowClassName.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            separatorLineBelowClassName.heightAnchor.constraint(equalToConstant: 1),
            
            classRoomLabel.topAnchor.constraint(equalTo: separatorLineBelowClassName.bottomAnchor, constant: 20),
            classRoomLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            classRoomLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            tableView.topAnchor.constraint(equalTo: classRoomLabel.bottomAnchor, constant: 0),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tableViewHeightConstraint,
            
            collectionView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            collectionViewHeightConstraint,
            
            professorNameLabel.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 20),
            professorNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            professorNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            separatorLineBelowProfessorName.topAnchor.constraint(equalTo: professorNameLabel.bottomAnchor, constant: 10),
            separatorLineBelowProfessorName.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separatorLineBelowProfessorName.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            separatorLineBelowProfessorName.heightAnchor.constraint(equalToConstant: 1),
            
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
        toggleButton.setTitle(isCollectionViewExpanded ? "時間割を表示しない▼" : "時間割を表示する▶︎", for: .normal)
        toggleButton.setTitleColor(.black, for: .normal)
        toggleButton.addTarget(self, action: #selector(toggleCollectionView), for: .touchUpInside)
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(toggleButton)
        
        NSLayoutConstraint.activate([
            toggleButton.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: -25), // 固定位置
            toggleButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -50), // 固定位置
            toggleButton.widthAnchor.constraint(equalToConstant: 200),
            toggleButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    /*
    @objc private func toggleCollectionView() {
        let isExpanded = collectionViewHeightConstraint.constant > 0
        collectionViewHeightConstraint.constant = isExpanded ? 0 : 260
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }*/
    
    @objc private func toggleCollectionView() {
        isCollectionViewExpanded.toggle() // フラグを反転させる
        collectionViewHeightConstraint.constant = isCollectionViewExpanded ? 260 : 0
        toggleButton.setTitle(isCollectionViewExpanded ? "時間割を表示しない▼" : "時間割を表示する▶︎", for: .normal)

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        
        updateContentViewHeight(rowCount: tableView.numberOfRows(inSection: 0))
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
            classNameLabel.text = "教科名\n\(classInfo.name)"
            classRoomLabel.text = "時間・教室"
            professorNameLabel.text = "担当教授名\n\(classInfo.professorName)"
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
    /*
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
                tableView.reloadData()
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
        
        // 同じclassIdを持つデータをclassesToRegisterから削除
        if let indexToRemove = classDataManager.classesToRegister.firstIndex(where: { $0.classId == newClassData.classId }) {
            classDataManager.classesToRegister.remove(at: indexToRemove)
            print("classIdが\(newClassData.classId)のデータがclassesToRegisterから削除されました")
        }

        // classDataManager.classListに追加
        classDataManager.classList.append(newClassData)
        // classDataManager.classListをソート
        classDataManager.classList.sort(by: { $0.dayAndPeriod < $1.dayAndPeriod })
        collectionView.reloadData()
        tableView.reloadData()
        // CoreDataに反映
        classDataManager.replaceClassDataIntoDB(classInformationList: classDataManager.classList)
    }
    
    @objc private func saveButtonTapped() {
        guard let visibleCells = tableView.visibleCells as? [EditableTableViewCell] else { return }
        
        for cell in visibleCells {
            if let indexPath = tableView.indexPath(for: cell) {
                let classData = classDataManager.classList.filter { $0.classId == classInfo?.classId }[indexPath.row]
                
                if let text = cell.textField.text, let colonRange = text.range(of: ":") {
                    let prefixText = String(text[..<colonRange.upperBound])
                    let editedRoomName = String(text[colonRange.upperBound...])
                    classData.room = prefixText + editedRoomName
                } else {
                    classData.room = cell.textField.text ?? ""
                }
                
                updateCoreDataClassRoom(for: classData)
            }
        }
        
        if let updatedClassInfo = classInfo {
            delegate?.classInfoDidUpdate(updatedClassInfo)
        }
    }*/
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
