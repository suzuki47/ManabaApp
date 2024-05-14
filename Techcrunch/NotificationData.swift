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
    var notificationTiming: Data
    var identifier: Int
    
    init(title: String, subTitle: String, notificationTiming: Data, identifier: Int) {
        self.title = title
        self.subTitle = subTitle
        self.notificationTiming = notificationTiming
        self.identifier = identifier
    }
    
    func getTitle() -> String {
        return title
    }
    
    func getSubTitle() -> String {
        return subTitle
    }
    
    func getNotificationTiming() -> Data {
        return notificationTiming
    }
    
    func getIdentifier() -> Int {
        return identifier
    }
    
}
