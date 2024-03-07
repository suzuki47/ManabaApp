//
//  ClassDataManager.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2024/02/05.
//

import Foundation
import CoreData

class ClassDataManager: DataManager {
    
    var classList: [ClassInformation] = []
    var professorList: [ClassAndProfessor] = []
    var unregisteredClassList: [UnregisteredClassInformation] = []
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
                
                let classData = ClassData(classId: classId, className: className, classRoom: classRoom, professorName: professorName, classURL: classURL, classIdChangeable: 0)
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
            return ClassData(classId: 0, className: "授業情報を取得できませんでした", classRoom: "", professorName: "", classURL: "", classIdChangeable: 0)
        }
        
        if line == 7 {
            return ClassData(classId: 0, className: "次は空きコマです", classRoom: "", professorName: "", classURL: "", classIdChangeable: 0)
        } else if 7 * row + line < DataManager.classDataList.count {
            return DataManager.classDataList[7 * row + line]
        } else {
            return ClassData(classId: 0, className: "時間外です。", classRoom: "行く当てなし", professorName: "", classURL: "", classIdChangeable: 0)
        }
    }
    
    func getClassDataFromManaba() {
        // TODO: 実際のスクレイピング処理をここに実装
        print("ダミーデータを使用してクラスデータを取得します")
    }
    
    func replaceClassDataIntoList(classId: Int, className: String, classRoom: String, classURL: String) {
        if classId < DataManager.classDataList.count {
            DataManager.classDataList[classId].setClassName(className)
            DataManager.classDataList[classId].setClassRoom(classRoom)
            DataManager.classDataList[classId].setClassURL(classURL)
        } else {
            // 新しいClassDataをリストに追加する場合
            let newClassData = ClassData(classId: classId, className: className, classRoom: classRoom, professorName: "", classURL: classURL, classIdChangeable: 0)
            DataManager.classDataList.append(newClassData)
        }
    }
    
    func replaceClassDataIntoClassList(classId: Int, className: String, classRoom: String, professorName: String, classURL: String, classIdChangeable: Int) {
        // 新しいClassDataインスタンスを作成
        let classData = ClassData(classId: classId, className: className, classRoom: classRoom, professorName: professorName, classURL: classURL, classIdChangeable: classIdChangeable)
        // classDataListが実際に存在し、適切な範囲のインデックスにアクセスしていることを確認
        if classId > 0 && classId <= ClassDataManager.classDataList.count {
            
                ClassDataManager.classDataList[classId] = classData
        } else {
            print("Error: classId is out of valid range (1 to \(ClassDataManager.classDataList.count))")
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
                dataStore.classIdChangeable = Int16(classData.classIdChangeable)
                
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
    
    func getUnChangeableClassDataFromManaba() async {
        let classURL = "https://ct.ritsumei.ac.jp/ct/home_course?chglistformat=timetable"
        let SVC = await SecondViewController()
        let cookieString = await SVC.assembleCookieString()
        let scraper = ManabaScraper(cookiestring: cookieString)
        
        print("授業スクレイピングテスト（時間割）：スタート")
        
        do {
            self.classList = try await scraper.getRegisteredClassDataFromManaba(urlString: classURL, cookieString: cookieString)
            print("授業スクレイピングテスト（時間割）：フィニッシュ")
            // スクレイピングで取得した授業情報をデータベースとクラスリストに反映
            for classInfo in self.classList {
                // `classInfo` からID、名前、教室名、URLを抽出
                let classId = Int(classInfo.id) ?? 0 // IDをIntに変換。変換できない場合は0を設定
                let className = classInfo.name
                let classRoom = classInfo.room
                let classURL = classInfo.url
                
                // データベースに授業データを反映
                // 注意: replaceClassDataIntoDBメソッドの実装が示されていないため、実際のメソッドシグネチャに合わせて調整してください。
                // 例: replaceClassDataIntoDB(classId: classId, className: className, classRoom: classRoom, classURL: classURL)
                
                // クラスリストに授業データを反映
                replaceClassDataIntoClassList(classId: classId, className: className, classRoom: classRoom, professorName: "", classURL: classURL, classIdChangeable: 0)
            }
            // classListの中身を確認
            print("クラスリストの内容確認:")
            for classInfo in self.classList {
                print("ID: \(classInfo.id), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url)")
            }
        } catch {
            print("スクレイピング中にエラーが発生しました: \(error)")
        }
        
    }
    // TODO: スクレイピング以降の機能の実装
    func getChangeableClassDataFromManaba() async {
        let classURL = "https://ct.ritsumei.ac.jp/ct/home_course?chglistformat=timetable"
        let SVC = await SecondViewController()
        let cookieString = await SVC.assembleCookieString()
        let scraper = ManabaScraper(cookiestring: cookieString)
        print("授業スクレイピングテスト（時間割以外）：スタート")
        
        do {
            self.unregisteredClassList = try await scraper.getUnRegisteredClassDataFromManaba(urlString: classURL, cookieString: cookieString)
            print("授業スクレイピングテスト（時間割以外）：フィニッシュ")
        } catch {
            print("スクレイピング中にエラーが発生しました: \(error)")
        }
        
    }
    // TODO: スクレイピング以降の機能の実装
    func getProfessorNameFromManaba() async {
        let classURL = "https://ct.ritsumei.ac.jp/ct/home_course?chglistformat=list"
        let SVC = await SecondViewController()
        let cookieString = await SVC.assembleCookieString()
        let scraper = ManabaScraper(cookiestring: cookieString)
        print("教授名スクレイピングテスト：スタート")
        
        do {
            self.professorList = try await scraper.getProfessorNameFromManaba(urlString: classURL, cookieString: cookieString)
            print("教授名スクレイピングテスト：フィニッシュ")
            for (index, classInfo) in classList.enumerated() {
                if let matchingProfessor = professorList.first(where: { $0.className == classInfo.name }) {
                    classList[index].professorName = matchingProfessor.professorName
                }
            }
            
        } catch {
            print("スクレイピング中にエラーが発生しました: \(error)")
        }
        
    }
}

