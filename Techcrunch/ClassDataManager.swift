//
//  ClassDataManager.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2023/11/01.
//

import UIKit

/*class ClassDataManager: DataManager {
    
    static var className: UILabel?
    static var classRoom: UILabel?
    var name: String?
    
    class func prepareForClassWork(dataName: String, context: UIViewController) {
        prepareForWork(dataName: dataName, context: context)
    }
    
    class func setTextView(_ ClassName: UILabel, _ ClassRoom: UILabel) {
        self.className = nil
        self.classRoom = nil
        self.className = ClassName
        self.classRoom = ClassRoom
    }
    
}*/

/*
 import UserNotifications

 // ユーザーに通知の許可をリクエストする関数
 func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
     UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
         DispatchQueue.main.async {
             completion(granted)
         }
     }
 }

 // 曜日の文字列を週の番号に変換するヘルパー関数
 func convertDayToWeekdayNumber(day: String) -> Int {
     let dayIndexMap: [String: Int] = ["月": 2, "火": 3, "水": 4, "木": 5, "金": 6, "土": 7, "日": 1]  // 日本のカレンダーに基づいています
     return dayIndexMap[day] ?? 0
 }

 // 時限を時刻に変換するヘルパー関数
 func convertPeriodToTime(period: Int) -> (hour: Int, minute: Int) {
     let periodTimeMap: [Int: (hour: Int, minute: Int)] = [
         1: (9, 0),   // 1時限目
         2: (10, 40), // 2時限目
         3: (13, 0),  // 3時限目
         4: (14, 40), // 4時限目
         5: (16, 20), // 5時限目
         6: (18, 0),  // 6時限目
         7: (19, 40)  // 7時限目
     ]
     return periodTimeMap[period] ?? (0, 0)
 }

 // 通知をスケジュールする関数
 func scheduleClassNotifications(classSchedule: [(day: String, period: Int, room: String, className: String)]) {
     let calendar = Calendar.current

     for classInfo in classSchedule {
         let content = UNMutableNotificationContent()
         content.title = "\(classInfo.className)"
         content.body = "教室: \(classInfo.room)"
         content.sound = UNNotificationSound.default

         let weekdayNumber = convertDayToWeekdayNumber(day: classInfo.day)
         let (hour, minute) = convertPeriodToTime(period: classInfo.period)
         
         var dateComponents = DateComponents()
         dateComponents.weekday = weekdayNumber
         dateComponents.hour = hour
         dateComponents.minute = minute

         let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
         let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

         UNUserNotificationCenter.current().add(request) { error in
             if let error = error {
                 print("Error scheduling notification: \(error)")
             }
         }
     }
 }

 // この関数をボタンのアクションに結び付ける
 func onScheduleButtonPressed() {
     requestNotificationPermission { granted in
         if granted {
             let classSchedule = [
                 // ここに解析したクラススケジュールをタプルのリストとして入れます
                 ("月", 1, "R103", "言語処理系"),
                 ("月", 2, "R103", "ビッグデータ解析"),
                 // 以下、全ての授業について同様に追加...
             ]
             scheduleClassNotifications(classSchedule: classSchedule)
         } else {
             print("Notification permission not granted")
         }
     }
 }

 */
