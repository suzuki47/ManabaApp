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
                    print("Core Dataの更新に成功しました（\(dayAndPeriod)）")

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

