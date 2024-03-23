//
//  ClassInfoPopupViewController.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2024/03/07.
//

import UIKit

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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupEditButton()
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
        ])
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
            self.classInfo?.id = String(timeId)
            
            // 更新後の情報でUIを更新する処理をここに追加
            self.updateUIWithClassInfo()
            
            // 更新されたclassInfoの内容をログに出力
            if let updatedClassInfo = self.classInfo {
                print("更新された授業情報：")
                print("ID: \(updatedClassInfo.id), 教室: \(updatedClassInfo.room)")
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
