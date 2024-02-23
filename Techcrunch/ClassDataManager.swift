//
//  ClassDataManager.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2024/02/05.
//

import Foundation
import CoreData

class ClassDataManager: DataManager {
    //TODO: overrideしていいの？
    override init(dataName: String, context: NSManagedObjectContext) {
        super.init(dataName: dataName, context: context)
    }
    
    func getClassDataList() -> [ClassData] {
        return DataManager.classDataList
    }
    
    func loadClassData() {
        print("今からクラスデータをロードします。ClassDataManager")
        
        let fetchRequest: NSFetchRequest<MyClassDataStore> = MyClassDataStore.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
            
            DataManager.classDataList.removeAll() // Ensure the list is empty before loading new data
            for result in results {
                guard let classId = result.classId as? Int,
                      let className = result.classTitle,
                      let classRoom = result.classRoom,
                      let professorName = result.professorName,
                      let classURL = result.classURL else {
                    continue // Skip this result if any required field is missing
                }
                
                let classData = ClassData(classId: classId, className: className, classRoom: classRoom, professorName: professorName, classURL: classURL)
                DataManager.classDataList.append(classData)
                
                print("\(classId)番目の\(className)をロードしました。ClassDataManager")
            }
            print("クラスデータロード完了!。ClassDataManager")
        } catch {
            print("クラスデータの読み込みに失敗しました: \(error)")
        }
    }
    
    func checkClassData() -> Bool {
        // クラスデータが特定の数（例えば49）に達しているかチェック
        return getClassDataList().count == 49
    }
    
    func resetClassData() {
        // すべてのクラスデータをリセットする
        print("ClassDataの数が\(getClassDataList().count)しかなかったので初期化します。ClassDataManager")
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "MyClassDataStore")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            // データベースの初期化処理をここに実装
        } catch {
            print("データのリセットに失敗しました: \(error)")
        }
    }
    
    // 現在の授業情報を取得するメソッド
    func getClassInfor() -> ClassData {
        let now = Date()
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: now) - 1 // 日曜日は1、月曜日は2、...、土曜日は7
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let totalMinutes = hour * 60 + minute
        
        var row: Int
        var line: Int
        
        switch dayOfWeek {
        case 2...7: // Calendarで月曜日は2となるため、調整して月曜日=0に
            row = dayOfWeek - 2
        default:
            row = 6 // 日曜日または範囲外の場合
        }
        
        // 授業時間(line)の決定
        if totalMinutes < 510 {
            line = 0
        } else if totalMinutes < 610 {
            line = 1
        } else if totalMinutes < 750 {
            line = 2
        } else if totalMinutes < 850 {
            line = 3
        } else if totalMinutes < 950 {
            line = 4
        } else if totalMinutes < 1050 {
            line = 5
        } else if totalMinutes < 1150 {
            line = 6
        } else {
            line = 7
        }
        
        if DataManager.classDataList.count != 49 {
            return ClassData(classId: 0, className: "授業情報を取得できませんでした", classRoom: "", professorName: "", classURL: "")
        }
        
        if line == 7 {
            return ClassData(classId: 0, className: "次は空きコマです", classRoom: "", professorName: "", classURL: "")
        } else if 7 * row + line < DataManager.classDataList.count {
            return DataManager.classDataList[7 * row + line]
        } else {
            return ClassData(classId: 0, className: "時間外です。", classRoom: "行く当てなし", professorName: "", classURL: "")
        }
    }
    
    func getClassDataFromManaba() {
        // TODO: 実際のスクレイピング処理をここに実装
        print("ダミーデータを使用してクラスデータを取得します")
    }
    
    func getProfessorNameFromManaba() {
        // TODO: 実際のスクレイピング処理をここに実装
        print("ダミーデータを使用して教授名を取得します")
    }
    
    func replaceClassDataIntoList(classId: Int, className: String, classRoom: String, classURL: String) {
        if classId < DataManager.classDataList.count {
            DataManager.classDataList[classId].setClassName(className)
            DataManager.classDataList[classId].setClassRoom(classRoom)
            DataManager.classDataList[classId].setClassURL(classURL)
        } else {
            // 新しいClassDataをリストに追加する場合
            let newClassData = ClassData(classId: classId, className: className, classRoom: classRoom, professorName: "", classURL: classURL)
            DataManager.classDataList.append(newClassData)
        }
    }
    
    func replaceClassDataIntoDB() {
        for classData in DataManager.classDataList {
            let fetchRequest: NSFetchRequest<MyClassDataStore> = MyClassDataStore.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "classId == %d", Int16(classData.getClassId()))
            
            do {
                let results = try context.fetch(fetchRequest)
                let dataStore: MyClassDataStore
                if let existingDataStore = results.first {
                    dataStore = existingDataStore
                } else {
                    // CoreDataに存在しない場合は新しいエンティティを作成
                    dataStore = MyClassDataStore(context: context)
                    dataStore.classId = Int16(classData.getClassId())
                }
                
                // データストアのプロパティを更新
                dataStore.classTitle = classData.getClassName()
                dataStore.classRoom = classData.getClassRoom()
                dataStore.classURL = classData.getClassURL()
                
                try context.save()
            } catch {
                print("Core Dataの更新に失敗しました: \(error)")
            }
        }
    }
    
    func insertClassDataIntoDB(classData: ClassData) {
        // 新しいMyClassDataStoreエンティティのインスタンスを作成
        let newClassData = MyClassDataStore(context: self.context)
        
        // エンティティのプロパティを設定
        newClassData.classId = Int16(classData.getClassId())
        newClassData.classTitle = classData.getClassName()
        newClassData.classRoom = classData.getClassRoom()
        newClassData.classURL = classData.getClassURL()
        
        // コンテキストを保存して変更を永続化ストアに反映
        do {
            try self.context.save()
            print("\(dataName)に\(classData.getClassName())を追加しました。")
        } catch {
            print("\(dataName)への追加に失敗しました: \(error)")
        }
    }
    
    // TODO
    func resetAlltaskList() {
        // すべてのクラスデータに関連付けられたタスクリストをリセット
        let fetchRequest: NSFetchRequest<MyClassDataStore> = MyClassDataStore.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
            results.forEach { classData in
                // タスクリストをリセットする処理を実装
                // TODO: タスクリストリセットロジックの実装
            }
            try context.save()
        } catch {
            print("タスクリストのリセットに失敗しました: \(error)")
        }
    }
}

