//
//  NotifyManager.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2023/10/19.
//

import UserNotifications

class NotifyManager {
    
    // シングルトンインスタンス
    static let shared = NotifyManager()
    
    // NotificationData型の配列
    var notificationList: [NotificationData] = []
    
    // プライベートイニシャライザで外部からのインスタンス化を防ぐ
    private init() {}
    
    func addNotifications(for task: TaskData) {
        guard let timings = task.notificationTiming else { return }
        
        let dateFormatter = DateArrayTransformer.notificationDateFormatter()
        let dueDateString = dateFormatter.string(from: task.dueDate)
        
        for timing in timings {
            let taskIdInt = task.taskId // taskId はすでに Int 型なので直接使用
            let notification = NotificationData(
                title: task.taskName,
                subTitle: dueDateString,
                notificationTiming: timing,
                identifier: taskIdInt,
                repeatble: false
            )
            notificationList.append(notification)
        }

        for notification in notificationList {
            print("Title: \(notification.title), SubTitle: \(notification.subTitle), Timing: \(notification.notificationTiming), Identifier: \(notification.identifier), Repeatable: \(notification.repeatable)")
        }
    }
    // タスク用の通知追加メソッド
    func addTaskNotifications(for task: TaskData) {
        guard let timings = task.notificationTiming else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let dueDateString = dateFormatter.string(from: task.dueDate)
        
        for timing in timings {
            let taskIdInt = task.taskId // taskId はすでに Int 型なので直接使用
            let notification = NotificationData(
                title: task.taskName,
                subTitle: dueDateString,
                notificationTiming: timing,
                identifier: taskIdInt,
                repeatble: false
            )
            notificationList.append(notification)
        }
        //printNotifications()
    }
    
    // クラス情報用の通知追加メソッド
    func addClassNotifications(for classInfo: ClassData) {
        // 通知が有効かどうかを確認
        guard classInfo.isNotifying else {
            print("Notification is not enabled for this class")
            return
        }
        
        guard let (dayOfWeek, periodStartTime) = getDayAndTime(from: String(classInfo.dayAndPeriod)) else {
            print("Invalid class ID")
            return
        }

        
        let notificationDate = getNextDate(for: dayOfWeek, time: periodStartTime)
        let identifier = Int(classInfo.dayAndPeriod)
        
        let notification = NotificationData(
            title: classInfo.name,
            subTitle: classInfo.room,
            notificationTiming: notificationDate,
            identifier: identifier,
            repeatble: true
        )
        
        notificationList.append(notification)
        //printNotifications()
    }
    
    // NotificationListの内容をコンソールに出力するメソッド
    func printNotifications() {
        for notification in notificationList {
            print("Title: \(notification.title), SubTitle: \(notification.subTitle), Timing: \(notification.notificationTiming), Identifier: \(notification.identifier), Repeatable: \(notification.repeatable)")
        }
    }
    
    private func getDayAndTime(from dayAndPeriod: String) -> (Int, String)? {
        guard let dayAndPeriod = Int(dayAndPeriod) else { return nil }
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let times = ["08:30", "10:10", "12:30", "14:10", "15:50", "17:25", "19:10"]
        
        let periodIndex = dayAndPeriod / 7
        let dayIndex = dayAndPeriod % 7
        
        guard dayIndex < days.count, periodIndex < times.count else { return nil }
        
        return (dayIndex, times[periodIndex])
    }
    
    private func getNextDate(for dayOfWeek: Int, time: String) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        var components = DateComponents()
        components.weekday = dayOfWeek + 2 // Calendar's weekday starts from Sunday (1), so Monday is 2.
        components.hour = Int(time.split(separator: ":")[0])
        components.minute = Int(time.split(separator: ":")[1])
        
        // Find the next occurrence of the specified weekday and time
        let nextDate = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTimePreservingSmallerComponents)
        
        return nextDate ?? now
    }
    
    func getNotifications() -> [NotificationData] {
        return notificationList
    }
    
    // 通知をスケジュールするメソッド
    func scheduleNotifications(completion: @escaping () -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                let dispatchGroup = DispatchGroup()
                for notification in self.notificationList {
                    dispatchGroup.enter()
                    self.scheduleNotification(notification) {
                        dispatchGroup.leave()
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    completion()
                }
            } else {
                print("Notification permission denied.")
                completion()
            }
        }
    }
    
    private func scheduleNotification(_ notification: NotificationData, completion: @escaping () -> Void) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.subTitle
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.weekday, .hour, .minute], from: notification.notificationTiming)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: notification.repeatable)
        
        let request = UNNotificationRequest(identifier: String(notification.identifier), content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            }
            completion()
        }
    }
    /*
    func scheduleNotification(at date: Date, title: String, subTitle: String, taskId: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = subTitle
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = "task_\(taskId)_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            }
        }
    }
     */
    
    // スケジュールされている通知を確認するメソッド
    func listScheduledNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            for request in requests {
                let content = request.content
                let trigger = request.trigger as? UNCalendarNotificationTrigger
                let triggerDate = trigger?.nextTriggerDate()
                
                print("Notification ID: \(request.identifier)")
                print("Title: \(content.title)")
                print("Body: \(content.body)")
                print("Next Trigger Date: \(String(describing: triggerDate))")
            }
        }
    }
    
    // 全ての通知を削除するメソッド
    func removeAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        notificationList.removeAll()
        print("All notifications have been removed.")
    }
}

