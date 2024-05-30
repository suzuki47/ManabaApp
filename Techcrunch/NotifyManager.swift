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
    
    func addNotifications(for task: TaskInformation) {
        guard let timings = task.notificationTiming else { return }
        
        let dateFormatter = DateArrayTransformer.notificationDateFormatter()
        let dueDateString = dateFormatter.string(from: task.dueDate)
        
        for timing in timings {
            let notification = NotificationData(
                title: task.taskName,
                subTitle: dueDateString,
                notificationTiming: timing,
                identifier: task.taskId,
                repeatble: false
            )
            notificationList.append(notification)
        }
        for notification in notificationList {
            print("Title: \(notification.title), SubTitle: \(notification.subTitle), Timing: \(notification.notificationTiming), Identifier: \(notification.identifier), Repeatable: \(notification.repeatable)")
        }
    }
    
    // クラス情報用の通知追加メソッド
    func addClassNotifications(for classInfo: ClassInformation) {
        guard let (dayOfWeek, periodStartTime) = getDayAndTime(from: classInfo.id) else {
            print("Invalid class ID")
            return
        }
        
        let notificationDate = getNextDate(for: dayOfWeek, time: periodStartTime)
        let identifier = Int(classInfo.id) ?? 0
        
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
    
    private func getDayAndTime(from id: String) -> (Int, String)? {
        guard let classId = Int(id) else { return nil }
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let times = ["08:30", "10:10", "12:30", "14:10", "15:50", "17:30", "19:10"]
        
        let periodIndex = classId / 7
        let dayIndex = classId % 7
        
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
    func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                for notification in self.notificationList {
                    self.scheduleNotification(notification)
                }
            } else {
                print("Notification permission denied.")
            }
        }
    }
    
    private func scheduleNotification(_ notification: NotificationData) {
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
        }
    }
    
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
    /*
    // Schedule notification
    func scheduleNotification(for taskName: String, dueDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "タスク通知"
        content.body = "タスク「\(taskName)」の期限時間です！"
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: taskName, content: content, trigger: trigger)
        
        let center = UNUserNotificationCenter.current()
        center.add(request) { error in
            if let error = error {
                print("Error: \(error)")
            }
        }
    }
    
    func scheduleClassroomNotification(nextClass: (nextTiming: Date?, className: String, classRoom: String)?) {
        guard let nextClass = nextClass, let nextTiming = nextClass.nextTiming else {
            print("No next class found")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "次の授業情報"
        content.body = "30分後に「\(nextClass.className)」が開始されます。教室: \(nextClass.classRoom)"
        
        let fireDate = nextTiming.addingTimeInterval(-30 * 60)
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: "nextClassNotification", content: content, trigger: trigger)
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Notification Error:", error)
            }
        }
        
        let clearTriggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextTiming.addingTimeInterval(30 * 60))
        let clearTrigger = UNCalendarNotificationTrigger(dateMatching: clearTriggerDate, repeats: false)
        let clearContent = UNMutableNotificationContent()
        let clearRequest = UNNotificationRequest(identifier: "clearNextClassNotification", content: clearContent, trigger: clearTrigger)
        
        notificationCenter.add(clearRequest) { (error) in
            if error == nil {
                notificationCenter.removeDeliveredNotifications(withIdentifiers: ["nextClassNotification"])
            }
        }
    }*/
}

