//
//  NotificationData.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2024/05/12.
//

import Foundation

class NotificationData {
    var title: String
    var subTitle: String
    var notificationTiming: Date
    var identifier: Int
    var repeatable: Bool
    
    init(title: String, subTitle: String, notificationTiming: Date, identifier: Int, repeatble: Bool) {
        self.title = title
        self.subTitle = subTitle
        self.notificationTiming = notificationTiming
        self.identifier = identifier
        self.repeatable = repeatble
    }
    
    func getTitle() -> String {
        return title
    }
    
    func getSubTitle() -> String {
        return subTitle
    }
    
    func getNotificationTiming() -> Date {
        return notificationTiming
    }
    
    func getIdentifier() -> Int {
        return identifier
    }
    
    func getRepeatble() -> Bool {
        return repeatable
    }
    
}
