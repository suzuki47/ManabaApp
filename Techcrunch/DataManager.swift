//
//  DataManager.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2023/12/29.
//

import Foundation
import CoreData
import UserNotifications

class DataManager {

    var dataName: String
    var dataCount: Int16 = 0
    var dataList: [DataStore] = [] // Core DataのDataStoreエンティティを使用
    let context: NSManagedObjectContext // Core Dataのコンテキスト

    init(dataName: String, context: NSManagedObjectContext) {
        self.dataName = dataName
        self.context = context
        loadData()
    }
    
    func prepareForWork(dataName: String, firstNum: Int16) {
            self.dataName = dataName
            self.dataCount = firstNum
            self.dataList = [] // DataStoreエンティティの空の配列を初期化

            // 日付フォーマットの設定（必要に応じて）
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            formatter.locale = Locale(identifier: "ja_JP")
            // formatterを適切なプロパティに保存するか、必要に応じて使用する
        }

    func loadData() {
        let request: NSFetchRequest<DataStore> = DataStore.fetchRequest()
        do {
            dataList = try context.fetch(request)
            print("データをロードしました。DataManager")
        } catch {
            print("データの読み込みに失敗しました。")
        }
        
        if let lastItem = dataList.last {
            let ID = lastItem.id
            dataCount = ID + 1
            print("最後の要素のID: \(ID)")
        } else {
            // 配列が空の場合の処理
            print("配列に要素がありません。")
        }
        
    }

    func addData(title: String, subTitle: String, notificationTimings: [Date] = []) {
        let newData = DataStore(context: context)
        newData.title = title
        newData.subtitle = subTitle
        newData.notificationTiming = notificationTimings as NSArray
        newData.id = Int16(dataCount)
        dataCount += 1
        // dataList配列に新しいDataStoreインスタンスを追加
        dataList.append(newData)

        saveContext()
    }
    
    func removeData(at index: Int) {
        // dataListから指定されたインデックスのデータを取得
        let dataToRemove = dataList[index]
        // UNUserNotificationCenterのインスタンスを取得
        let center = UNUserNotificationCenter.current()
        // 通知をキャンセルするための識別子を取得
        let identifier = "\(dataName)_\(dataToRemove.id)"
        // その識別子に対応する通知をキャンセル
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        // Core Dataのコンテキストからそのデータを削除
        context.delete(dataToRemove)
        // 変更を保存
        saveContext()
        // ローカルのdataListからも削除
        dataList.remove(at: index)
    }

    func updateData(data: DataStore, newTitle: String? = nil, newSubtitle: String? = nil, newNotificationTimings: [Date]? = nil) {
        if let newTitle = newTitle {
            data.title = newTitle
        }
        if let newSubtitle = newSubtitle {
            data.subtitle = newSubtitle
        }
        if let newNotificationTimings = newNotificationTimings {
            data.notificationTiming = newNotificationTimings as NSArray
        }

        saveContext()
    }

    func deleteData(data: DataStore) {
        context.delete(data)
        saveContext()
    }

    func saveContext() {
        do {
            try context.save()
        } catch {
            print("コンテキストの保存に失敗しました: \(error)")
        }
    }

}

