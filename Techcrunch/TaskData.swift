//
//  TaskData.swift
//  Techcrunch
//
//  Created by 鈴木悠太 on 2023/08/15.
//

import Foundation

struct TaskData {
    static var taskDates: [TaskData] = []
    let name: String
    let dueDate: Date
    let detail: String
    let taskType: Int
    // 通知日付が空でなければtrueを返す
    var isNotified: Bool {
            return !_notificationDates.isEmpty
        }
    private var _notificationDates: [Date] = []
    private var lastNotifiedDate: Date?
    
    public init(name: String, dueDate: Date, detail: String, taskType: Int, isNotified: Bool = false) {
        self.name = name
        self.dueDate = dueDate
        self.detail = detail
        self.taskType = taskType
        //self.isNotified = isNotified
        print("おおおおおおおおおおおおおおおおおお")
        print(TaskData.taskDates.count)
    }
    // 通知日付の公開用の配列を返す
    var notificationDates: [Date] {
        return _notificationDates.map { $0 }
    }
    // 新しい通知日付を追加する
    mutating func addNotificationDate(_ date: Date) {
            if _notificationDates.count < 3 {
                _notificationDates.append(date)
            } else {
                print("通知の上限に達しています。")
            }
        }
    // 指定されたインデックスの通知日付を削除する
    mutating func removeNotificationDate(at index: Int) {
            if index < _notificationDates.count {
                _notificationDates.remove(at: index)
            }
        }
    // すべての通知日付をクリアする
    mutating func clearNotificationDates() {
            self._notificationDates.removeAll()
        }

}

