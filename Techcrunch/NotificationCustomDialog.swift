//
//  NotificationCustomDialog.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2023/10/19.
//

import Foundation
import UIKit
import UserNotifications
import CoreData
/* 2/8
class NotificationCustomDialog: NSObject, UITableViewDelegate {
    
    weak var dialog: AddNotificationDialog?
    
    var notificationDates: [Date]
    var taskName: String
    weak var delegate: NotificationCustomAdapterDelegate?
    weak var adapter: NotificationCustomAdapter?
    
    init(notificationDates: [Date], taskName: String, delegate: NotificationCustomAdapterDelegate?, adapter: NotificationCustomAdapter?) {
        self.notificationDates = notificationDates
        self.taskName = taskName
        self.delegate = delegate
        self.adapter = adapter
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedDate = notificationDates[indexPath.row]
        
        let addNotificationDialog = AddNotificationDialog()
        addNotificationDialog.viewController = adapter
        addNotificationDialog.presentDatePickerAlert(title: "通知の日時を編集", selectedDate: selectedDate) { date in
            self.notificationDates[indexPath.row] = date
            self.delegate?.didUpdateNotificationDates(for: self.taskName, self.notificationDates)
            tableView.reloadData()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }




    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            notificationDates.remove(at: indexPath.row)
            delegate?.didUpdateNotificationDates(for: taskName, notificationDates)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
*/
