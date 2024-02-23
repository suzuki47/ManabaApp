//
//  Data.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2023/12/23.
//

import Foundation
/*
class Data {
    var id: Int //課題と授業の識別子
    var title: String //課題名と授業名
    var subtitle: String //締切（task）と教室名（class）
    var notificationTiming: [Date] //通知日時
    //var done: Bool //課題の提出の有無（classには関係ない）

    init(id: Int, title: String, subtitle: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.notificationTiming = []
        self.done = false
    }

    func getId() -> Int {
        return self.id
    }

    func getTitle() -> String {
        return self.title
    }

    func getSubtitle() -> String {
        return self.subtitle
    }

    func getNotificationTiming() -> [Date] {
        return self.notificationTiming
    }
    
    func getDone() -> Bool {
        return self.done
    }

    func replaceTitle(_ title: String) {
        self.title = title
    }

    func replaceSubtitle(_ subtitle: String) {
        self.subtitle = subtitle
    }
    
    func replaceDone(_ done: Bool) {
        self.done = done
    }

    //通知日時の追加
    func addNotificationTiming(_ newTiming: Date) {
        self.notificationTiming.append(newTiming)
        reorderNotificationTiming()
    }

    //指定した通知の削除
    func deleteNotificationTiming(_ notificationNum: Int) {
        self.notificationTiming.remove(at: notificationNum)
        reorderNotificationTiming()
    }

    //通知日時の先頭を削除（通知順）
    func deleteFinishedNotification() {
        self.notificationTiming.removeFirst()
        reorderNotificationTiming()
    }

    //通知日時のリロード
    func reorderNotificationTiming() {
        self.notificationTiming.sort()
    }
}
*/
