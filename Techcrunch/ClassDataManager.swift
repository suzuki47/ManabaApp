//
//  ClassDataManager.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2024/02/05.
//

import Foundation
import CoreData

class ClassDataManager: DataManager {
    
    var classList: [ClassData] = []
    var professorList: [ClassAndProfessor] = []
    var unregisteredClassList: [UnregisteredClassInformation] = []
    var classesToRegister: [ClassData] = []
    var keptClasses: [ClassData] = []
    var notificationStatus: [ClassIdAndIsNotifying] = []
    //TODO: overrideしていいの？
    override init(dataName: String, context: NSManagedObjectContext) {
        super.init(dataName: dataName, context: context)
    }
    /* 使われていない
    func getClassDataList() -> [ClassData] {
        return DataManager.classDataList
    }
    */
    // MyClassDataStoreからclassListへデータのロード
    func loadClassData() {
        print("今からクラスデータをロードします。ClassDataManager")
        
        let fetchRequest: NSFetchRequest<MyClassDataStore> = MyClassDataStore.fetchRequest()
        // dayAndPeriod で昇順にソートする NSSortDescriptor を追加
        let sortDescriptor = NSSortDescriptor(key: "dayAndPeriod", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            // 'context' が以前に初期化された NSManagedObjectContext インスタンスであると仮定
            let results = try context.fetch(fetchRequest)
            print("resultsの中身")
            // 結果をプリントする
            /*
            for result in results {
                print("Day and Period: \(result.dayAndPeriod), 通知のオンオフ: \(result.isNotifying)")
                // 他のプロパティもここに追加してプリントできます
                // 例: print("Class ID: \(result.classId)")
            }
             */
            // 新しいデータを追加する前に classList をクリア
            classList.removeAll()
            print("さあ、ロードしますよ")
            for result in results {
                // 非オプショナルのプロパティはそのまま使用し、オプショナルは安全にアンラップ
                let classId = result.classId
                let dayAndPeriod = result.dayAndPeriod // Int16 なのでキャスト不要
                let className = result.classTitle ?? "" // nil の場合はデフォルト値を提供
                let classRoom = result.classRoom ?? ""
                let professorName = result.professorName ?? ""
                let classURL = result.classURL ?? ""
                let classIdChangeable = result.classIdChangeable
                let isNotifying = result.isNotifying
                
                // 取得したデータで ClassInformation のインスタンスを作成
                let classInformation = ClassData(classId: Int(classId),
                                                        dayAndPeriod: Int(dayAndPeriod),
                                                        name: className,
                                                        room: classRoom,
                                                        url: classURL,
                                                        professorName: professorName,
                                                        classIdChangeable: classIdChangeable, isNotifying: isNotifying)
                // 新しいインスタンスを classList に追加
                classList.append(classInformation)
                
                print("dayAndPeriod:\(dayAndPeriod),授業名:\(className),教授名:\(professorName),通知のオンオフ:\(isNotifying)          in ClassDataManager")
            }
            print("クラスデータロード完了!。ClassDataManager")
        } catch {
            print("クラスデータの読み込みに失敗しました: \(error)")
        }
    }
    
    // taskURLからtaskIdを抽出する関数
    func extractTaskId(from url: String) -> Int? {
        let components = url.components(separatedBy: "_")
        var sevenDigitNumbers = [String]()
        
        for component in components {
            if component.count == 7, let _ = Int(component) {
                sevenDigitNumbers.append(component)
            }
        }
        
        if sevenDigitNumbers.count == 1 {
            // 7桁の数字が1つだけの場合、その数字を返す
            return Int(sevenDigitNumbers[0])
        } else if sevenDigitNumbers.count >= 2 {
            // 7桁の数字が2つ以上の場合、最初の2つを連結して14桁の数字を返す
            let concatenated = sevenDigitNumbers[0] + sevenDigitNumbers[1]
            return Int(concatenated)
        }
        
        return nil // 7桁の数字が見つからない場合
    }
    /* 使われていない
    func checkClassData() -> Bool {
        // クラスデータが特定の数（例えば49）に達しているかチェック
        return getClassDataList().count == 49
    }
     */
    /* 使われていない
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
    */
    /* 使われていない
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
        // 以下のやつらDataManagerじゃなくて、ClassDataManagerのclassListじゃね？
        if DataManager.classDataList.count != 49 {
            return ClassData(classId: 0, dayAndPeriod: 0, className: "授業情報を取得できませんでした", classRoom: "", professorName: "", classURL: "", classIdChangeable: false)
        }
        
        if line == 7 {
            return ClassData(classId: 0, dayAndPeriod: 0, className: "次は空きコマです", classRoom: "", professorName: "", classURL: "", classIdChangeable: false)
        } else if 7 * row + line < DataManager.classDataList.count {
            return DataManager.classDataList[7 * row + line]
        } else {
            return ClassData(classId: 0, dayAndPeriod: 0, className: "時間外です。", classRoom: "行く当てなし", professorName: "", classURL: "", classIdChangeable: false)
        }
    }
     */
    /* 使われていない
    func getClassDataFromManaba() {
        // TODO: 実際のスクレイピング処理をここに実装
        print("ダミーデータを使用してクラスデータを取得します")
    }
    */
    // MyClassDataStoreの全データを削除
    func emptyMyClassDataStore() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = MyClassDataStore.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("MyClassDataStoreの全データが削除されました。")
        } catch let error as NSError {
            print("全データの削除に失敗しました: \(error), \(error.userInfo)")
        }
    }
    /* 使われていない
    func replaceClassDataIntoList(dayAndPeriod: Int, className: String, classRoom: String, classURL: String) {
        if dayAndPeriod < DataManager.classDataList.count {
            DataManager.classDataList[dayAndPeriod].setClassName(className)
            DataManager.classDataList[dayAndPeriod].setClassRoom(classRoom)
            DataManager.classDataList[dayAndPeriod].setClassURL(classURL)
        } else {
            // 新しいClassDataをリストに追加する場合
            if let classId = extractTaskId(from: classURL) {
                let newClassData = ClassData(
                    classId: classId,
                    dayAndPeriod: dayAndPeriod,
                    className: className,
                    classRoom: classRoom,
                    professorName: "",
                    classURL: classURL,
                    classIdChangeable: false
                )
                DataManager.classDataList.append(newClassData)
            } else {
                print("Error: Could not extract classId from URL \(classURL)")
            }
        }
    }
    */
    // なぜDataManagerのclassDataListを確認してんの？
    /*
    func replaceClassDataIntoClassList(classId: Int, dayAndPeriod: Int, className: String, classRoom: String, professorName: String, classURL: String, classIdChangeable: Bool) {
        // 新しいClassDataインスタンスを作成
        let classData = ClassData(classId: classId, dayAndPeriod: dayAndPeriod, className: className, classRoom: classRoom, professorName: professorName, classURL: classURL, classIdChangeable: classIdChangeable)
        // classDataListが実際に存在し、適切な範囲のインデックスにアクセスしていることを確認
        if dayAndPeriod >= 0 && dayAndPeriod <= ClassDataManager.classDataList.count {
            
            ClassDataManager.classDataList[dayAndPeriod] = classData
        } else {
            print("Error: dayAndPeriod is out of valid range (1 to \(ClassDataManager.classDataList.count))")
        }
    }
    */
    
    func replaceClassDataIntoDB(classInformationList: [ClassData]) {
        // classInformationListにあるデータと同じclassIdを持つデータをMyClassDataStoreから引っ張ってくる
        for classInfo in classInformationList {
            let classId = Int64(classInfo.classId) // classId を Int64 に変換

            if let dayAndPeriod = Int16(exactly: classInfo.dayAndPeriod) {
                let fetchRequest: NSFetchRequest<MyClassDataStore> = MyClassDataStore.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "classId == %d", classId)

                do {
                    let results = try context.fetch(fetchRequest)
                    let dataStore: MyClassDataStore
                    if let existingDataStore = results.first(where: { $0.dayAndPeriod == dayAndPeriod }) {
                        dataStore = existingDataStore
                    } else {
                        dataStore = MyClassDataStore(context: context)
                        dataStore.classId = classId // classId を直接セット
                    }

                    // データストアのプロパティを更新
                    dataStore.dayAndPeriod = dayAndPeriod // dayAndPeriod を直接セット
                    dataStore.classTitle = classInfo.name
                    dataStore.classRoom = classInfo.room
                    dataStore.classURL = classInfo.url
                    dataStore.classIdChangeable = classInfo.classIdChangeable
                    dataStore.professorName = classInfo.professorName
                    dataStore.isNotifying = classInfo.isNotifying

                    try context.save()
                    print("Core Dataの更新に成功しました")

                } catch {
                    print("Core Dataの更新に失敗しました: \(error)")
                }
            } else {
                print("Error: Could not convert dayAndPeriod to Int16 for classId \(classId)")
            }
        }
        print("classListをCoreDataに保存しました")
        // データ保存後に全データをフェッチして表示
        fetchAllClassDataFromDB()
    }
    //TODO: dayAndPeriod以外でも限定する要素加えた方がいいかも
    func deleteClassDataFromDB(dayAndPeriod: Int) {
        let fetchRequest: NSFetchRequest<MyClassDataStore> = MyClassDataStore.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "dayAndPeriod == %d", dayAndPeriod)

        do {
            let results = try context.fetch(fetchRequest)
            for object in results {
                context.delete(object)
            }
            try context.save()
            print("Core DataからdayAndPeriodが\(dayAndPeriod)のデータを削除しました")
        } catch {
            print("Core Dataからの削除に失敗しました: \(error)")
        }
    }
    
    func fetchAllClassDataFromDB() {
        let fetchRequest: NSFetchRequest<MyClassDataStore> = MyClassDataStore.fetchRequest()
        
        do {
            let results = try context.fetch(fetchRequest)
            print("MyClassDataStoreの中身")
            for dataStore in results {
                print("ClassId: \(dataStore.classId), DayAndPeriod: \(dataStore.dayAndPeriod), Title: \(String(describing: dataStore.classTitle)), Room: \(String(describing: dataStore.classRoom)), URL: \(String(describing: dataStore.classURL)), Professor Name: \(String(describing: dataStore.professorName)), 変更可能な授業か:\(dataStore.classIdChangeable)")
            }
        } catch {
            print("フェッチに失敗しました: \(error)")
        }
    }
    /* 使われていない
    func insertClassDataIntoDB(classData: ClassData) {
        // 新しいMyClassDataStoreエンティティのインスタンスを作成
        let newClassData = MyClassDataStore(context: self.context)
        
        // エンティティのプロパティを設定
        if let classId = extractTaskId(from: classData.getClassURL()) {
            newClassData.classId = Int64(classId)
        } else {
            print("Error: Could not extract classId from URL \(classData.getClassURL())")
            // 必要に応じて、classId が取得できなかった場合の処理を追加します
        }
        
        newClassData.dayAndPeriod = Int16(classData.getDayAndPeriod())
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
    */
    // TODO
    /* 使われていない
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
    */
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
            
            /*
            for classInfo in self.classList {
                // `classInfo` からID、名前、教室名、URLを抽出
                let dayAndPeriod = Int(classInfo.dayAndPeriod) // dayAndPeriodをIntに変換。変換できない場合は0を設定
                let className = classInfo.name
                let classRoom = classInfo.room
                let classURL = classInfo.url
                
                // URL から classId を抽出
                if let classId = extractTaskId(from: classURL) {
                    // データベースに授業データを反映（ここにコードを追加する）

                    // クラスリストに授業データを反映
                    replaceClassDataIntoClassList(
                        classId: classId,
                        dayAndPeriod: dayAndPeriod,
                        className: className,
                        classRoom: classRoom,
                        professorName: "",
                        classURL: classURL,
                        classIdChangeable: false
                    )
                } else {
                    print("Error: Could not extract classId from URL \(classURL)")
                }
            }*/
            // classListの中身を確認
            print("クラスリストの内容確認:")
            for classInfo in self.classList {
                print("ClassId: \(classInfo.classId), DayAndPeriod: \(classInfo.dayAndPeriod), 名前: \(classInfo.name), 教室: \(classInfo.room), URL: \(classInfo.url)")
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

