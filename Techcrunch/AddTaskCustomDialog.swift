//
//  AddTaskCustomDialog.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2023/10/19.
//

import Foundation
import UIKit

class AddTaskCustomDialog {
    
    var viewController: UIViewController? // SecondViewControllerを参照するための変数
    
    func addNewTask() {
        guard let viewController = viewController else { return }
        // アラートコントローラを作成
        let alert = UIAlertController(title: "新しいタスク", message: "タスク、期日、詳細を入力してください", preferredStyle: .alert)
        
        // タイトル用のテキストフィールドを追加
        alert.addTextField { textField in
            textField.placeholder = "タスク"
        }
        
        // 期日用のテキストフィールドを追加
        alert.addTextField { textField in
            textField.placeholder = "期日（例：202307201030）"
        }
        
        // 詳細用のテキストフィールドを追加
        alert.addTextField { textField in
            textField.placeholder = "詳細"
        }
        
        // OKアクションを作成
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            // テキストフィールドのテキストを取得
            let title = alert.textFields?[0].text ?? ""
            let dueDateString = alert.textFields?[1].text ?? ""
            let detail = alert.textFields?[2].text ?? ""
            
            // 日付の文字列をDate型に変換
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMddHHmm"
            let dueDate = dateFormatter.date(from: dueDateString) ?? Date()
            
            // 新しいタスクを追加
            self?.addNewItem(name: title, dueDate: dueDate, detail: detail, taskType: 1)
            
            let taskdatastore = SecondViewController.newTaskDataStore()
            taskdatastore.name = title
            taskdatastore.dueDate = dueDate
            taskdatastore.detail = detail
            taskdatastore.taskType = 1
        }
        
        print("デバック1")
        
        // キャンセルアクションを作成
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        
        // アクションを追加
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        // アラートを表示
        viewController.present(alert, animated: true, completion: nil)
    }
    
    //タスクの追加・通知の設定
    func addNewItem(name: String, dueDate: Date, detail: String, taskType: Int) {
        print("うううううううううううううううううう")
        print(TaskData.shared.tasks.count)
        // 新しいタスクをデータモデルに追加
        let newTask = taskData(name: name, dueDate: dueDate, detail: detail, taskType: taskType, isNotified: false)
        TaskData.shared.tasks.append(newTask)
        print(TaskData.shared.tasks.count)
        // テーブルビューの最終行のIndexPathを作成
        //let indexPath = IndexPath(row: TaskData.taskDates.count - 1, section: 0)
        
        scheduleTaskNotification(for: name, at: dueDate.addingTimeInterval(-3600))
        
        // テーブルビューに新しい行を挿入
        //tableView.insertRows(at: [indexPath], with: .automatic)
        
        TaskData.shared.tasks.sort { $0.dueDate < $1.dueDate }
        
    }
    
    //期限1時間前に通知を設定する
    func scheduleTaskNotification(for taskName: String, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "タスクの期限通知"
        content.body = "タスク「\(taskName)」の期限が1時間後です！"
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: taskName, content: content, trigger: trigger)
        
        let center = UNUserNotificationCenter.current()
        center.add(request) { error in
            if let error = error {
                print("Error: \(error)")
            }
        }
        
        
    }
}
