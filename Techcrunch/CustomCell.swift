//
//  CustomTableViewCell.swift
//  Techcrunch
//
//  Created by 鈴木悠太 on 2023/08/02.
//

import UIKit
import CoreData


// Define the CustomCellDelegate protocol
protocol CustomCellDelegate: AnyObject {
    //func didTapButton(in cell: CustomCell)
    func didUpdateNotificationDates(with updatedTaskData: TaskData)
    func scheduleNotification(for taskName: String, dueDate: Date)
}

/* 2/8
class CustomCell: UITableViewCell {
    
    var managedObjectContext: NSManagedObjectContext?
    //タスクのデータがセットされたとき
    var taskData: taskData? {
        didSet {
            print("taskData set with isNotified: \(taskData?.isNotified ?? false)")
            print("taskDataがセットされました。isNotified: \(taskData?.isNotified ?? false)")
            updateUI()
        }
    }
    
    let button: UIButton = {
        let button = UIButton(type: .system)
        if let image = UIImage(systemName: "bell") {
            button.setImage(image, for: .normal)
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let taskLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let dueDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    weak var delegate: CustomCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(button)
        contentView.addSubview(taskLabel)
        contentView.addSubview(dueDateLabel)
        
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 40),
            taskLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            taskLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            dueDateLabel.leadingAnchor.constraint(equalTo: taskLabel.leadingAnchor),
            dueDateLabel.topAnchor.constraint(equalTo: taskLabel.bottomAnchor, constant: 4),
            dueDateLabel.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -12),
            
        ])
        
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    override func prepareForReuse() {
        /*super.prepareForReuse()
         // ここでセルの状態を初期化
         button.tintColor = UIColor.red // または適切なデフォルト色
         }*/
        super.prepareForReuse()
        // ここでセルのUIを初期化
        if let image = UIImage(systemName: "bell.slash.fill") {
            button.setImage(image, for: .normal)
        }
        taskLabel.text = nil
        dueDateLabel.text = nil
    }
    
    // 必須イニシャライザ。UITableViewCellのカスタムセルを初期化する際に呼ばれる。
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // 通知の日付が更新された場合のUI更新
    func didUpdateNotificationDates(with updatedTaskData: taskData) {
        self.taskData = updatedTaskData
        updateUI()
    }
    //通知の有無によるベルマークの更新
    func updateNotificationIcon(isNotified: Bool) {
        print("updateNotificationIcon called with isNotified: \(isNotified) for cell with taskData: \(taskData)")
        print("updateNotificationIconが呼び出されました。isNotified: \(isNotified)")
        let imageName = isNotified ? "bell.fill" : "bell.slash.fill"
        if let image = UIImage(systemName: imageName) {
            button.setImage(image, for: .normal)
        }
        //self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    func setNotificationDate(_ date: Date?) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        /*if let date = date {
         notificationLabel.text = "通知: \(formatter.string(from: date))"
         } else {
         notificationLabel.text = "通知なし"
         }*/
    }
    //ベルマークの更新
    /*func updateUI() {
     print("updateUI called for cell with taskData: \(taskData)")
     print("updateUIが呼び出されました。taskData?.isNotified: \(taskData?.isNotified ?? false)")
     taskLabel.text = taskData?.name
     
     updateNotificationIcon(isNotified: taskData?.isNotified ?? false)
     
     // 新しく追加する部分
     let formatter = DateFormatter()
     formatter.dateFormat = "yyyy/MM/dd HH:mm"
     let notificationDatesString = taskData?.notificationDates.map { formatter.string(from: $0) }.joined(separator: "\n")
     //notificationDatesLabel.text = notificationDatesString
     }*/
    
    func updateUI() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Error: Could not get app delegate")
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<DataStore> = DataStore.fetchRequest()
        
        // ここで適切なpredicateを設定して、必要なTaskDataStoreオブジェクトだけを取得できるようにする
        // 例: nameが特定のものであるTaskDataStoreを取得する場合
        // fetchRequest.predicate = NSPredicate(format: "name == %@", "特定のタスク名")
        
        do {
            let results = try context.fetch(fetchRequest)
            if let taskDataStore = results.first {
                // UIを更新する
                print("updateUI called for cell with taskDataStore: \(taskDataStore)")
                taskLabel.text = taskDataStore.title
                
                //let isNotified = taskDataStore.isNotified
                //updateNotificationIcon(isNotified: isNotified)
                
                // 新しく追加する部分
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy/MM/dd HH:mm"
                //とりあえず2024.01.03
                /*
                if let notificationDates = taskDataStore.notificationDates as? [Date] {
                    let notificationDatesString = notificationDates.map { formatter.string(from: $0) }.joined(separator: "\n")
                    //notificationDatesLabel.text = notificationDatesString
                }
                 */
            }
        } catch {
            print("Error: \(error)")
        }
        updateNotificationIcon(isNotified: taskData?.isNotified ?? false)
    }
    
    //画面遷移
    @objc func buttonTapped() {
        guard let viewController = delegate as? UIViewController else { return }
        
        // StoryboardからDetailViewControllerを取得
        let storyboard = UIStoryboard(name: "Main", bundle: nil)  // "Main"はStoryboardの名前、必要に応じて変更
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "NotificationCustomAdapter") as? NotificationCustomAdapter {

            
            // 通知日付データをDetailViewControllerに渡す
            detailVC.notificationDates = taskData?.notificationDates ?? []
            detailVC.taskDetail = taskData?.detail ?? ""
            
            // モーダル遷移
            viewController.present(detailVC, animated: true, completion: nil)
        }
        
    }
}
*/
