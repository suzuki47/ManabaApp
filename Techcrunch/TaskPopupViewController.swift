//
//  TaskPopupViewController.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2024/03/09.
//

import Foundation
import UIKit

class TaskPopupViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var taskName: String?
    var tableView: UITableView!
    let dummyTimes = ["9:00", "10:00", "11:00", "12:00"] // ダミーデータ
    private let contentView = UIView() // contentViewをクラスレベルで定義
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0 // 複数行を許可
        label.textAlignment = .center
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupTableView()
        
        // タップジェスチャをビューに追加
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        view.addGestureRecognizer(tapGesture)
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
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .white // 背景色を白に設定
        contentView.layer.cornerRadius = 12 // 角を丸く
        view.addSubview(contentView)
        
        // 閉じるボタンの追加
        let closeButton = UIButton()
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("×", for: .normal)
        closeButton.setTitleColor(.black, for: .normal)
        closeButton.backgroundColor = .clear
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        closeButton.addTarget(self, action: #selector(closePopup), for: .touchUpInside)
        contentView.addSubview(closeButton)
        // コンテンツビューにメッセージラベルを追加
        contentView.addSubview(messageLabel)
        
        if let taskName = taskName {
            messageLabel.text = taskName
        }
        
        NSLayoutConstraint.activate([
            // コンテンツビューの制約
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8), // 画面の幅の80%
            contentView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5), // 画面の高さの50%
            
            // メッセージラベルの制約
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 閉じるボタンの制約
            closeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
    @objc private func closePopup() {
        dismiss(animated: true, completion: nil)
    }
    
    private func setupTableView() {
        tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        // tableViewの高さを固定値ではなく、動的に変更する場合（オプショナル）
        //tableView.heightAnchor.constraint(lessThanOrEqualToConstant: 200).isActive = true
        tableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tableView) // contentViewに追加
        
        NSLayoutConstraint.activate([
            // メッセージラベルの下にテーブルビューを配置
            tableView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50), // 閉じるボタンの上に配置
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dummyTimes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = dummyTimes[indexPath.row]
        return cell
    }
}
