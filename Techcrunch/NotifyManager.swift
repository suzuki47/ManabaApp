//
//  NotifyManager.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2023/10/19.
//

import UserNotifications

class NotifyManager {
    
    // Shared instance for singleton pattern
    static let shared = NotifyManager()
    
    private init() { }  // This prevents others from using the default '()' initializer for this class.
    
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
    }
}

