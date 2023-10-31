//
//  AddNotificationDialog.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2023/10/19.
//

import Foundation
import UIKit
import UserNotifications
import CoreData

class AddNotificationDialog {
    
    weak var viewController: UIViewController? // Presenting ViewControllerを参照するための変数
    
    func presentDatePickerAlert(title: String, selectedDate: Date, completion: @escaping (Date) -> Void) {
        let alert = UIAlertController(title: title, message: "\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.frame = CGRect(x: 15, y: 50, width: 250, height: 120)
        datePicker.date = selectedDate
        alert.view.addSubview(datePicker)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak datePicker] _ in
            if let selectedDate = datePicker?.date {
                completion(selectedDate)
            }
        }
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        guard let viewController = viewController else { return }
        viewController.present(alert, animated: true, completion: nil)

    }
}
