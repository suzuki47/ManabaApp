//
//  HTMLParser.swift
//  Techcrunch
//
//  Created by 鈴木悠太 on 2023/05/18.
//

import SwiftSoup
import Foundation
import WebKit
/*
struct TaskInformation {
    var taskName: String
    var dueDate: Date // 日付型で期限を保持
    var belongedClassName: String
    var taskURL: String
    var hasSubmitted: Bool // 提出済みかどうかのフラグ
    var notificationTiming: [Date]? // 通知タイミングとして複数の日時を持つ
    var taskId: Int // タスクID
}
 */
/*
struct ClassInformation {
    var classId: Int
    var dayAndPeriod: Int
    var name: String
    var room: String
    var url: String
    var professorName: String
    var classIdChangeable: Bool
    var isNotifying: Bool//0の時、通知しない、1の時、通知する　空きコマは1
}
*/
struct UnregisteredClassInformation {
    var classId: Int
    var name: String
    var professorName: String
    var url: String
}

struct ClassAndProfessor {
    var className: String
    var professorName: String
}

struct ClassIdAndIsNotifying {
    var classId: Int
    var isNotifying: Bool
}

struct TaskIdAndNotificationTiming {
    var taskId: Int
    var notificationTiming: [Date]?
}

final class ManabaScraper {
    private let cookieString: String
    var classInformation: [ClassData] = []

    init(cookiestring: String){
        self.cookieString = cookiestring
    }
    /*
    func receiveRequest(dataName: String) async throws -> [(String, String)] {
        switch dataName {
        case "TaskData":
            return try await scrapeTaskDataFromManaba()
        case "ClassData":
            return try await fetchClassroomInfo(usingCookie: self.cookieString)
        default:
            throw NSError(domain: "Invalid dataName", code: -1, userInfo: nil)
        }
    }
    */
    /* 使われていない
    func scrapeTaskDataFromManaba() async throws -> [(String, String)] {
        let targetUrls = [
            "https://ct.ritsumei.ac.jp/ct/home_summary_query",
            "https://ct.ritsumei.ac.jp/ct/home_summary_survey",
            "https://ct.ritsumei.ac.jp/ct/home_summary_report"
        ]
        
        var results = [(String, String)]()
        for targetUrl in targetUrls {
            var request = URLRequest(url: URL(string: targetUrl)!)
            request.httpMethod = "GET"
            request.addValue(self.cookieString, forHTTPHeaderField: "Cookie")
            let (data, _) = try await URLSession.shared.data(for: request)

            do {
                let doc: Document = try SwiftSoup.parse(String(data: data, encoding: .utf8) ?? "")
                let links: Elements = try doc.select("#container > div.pagebody > div > table.stdlist tbody tr")
                for link in links.dropFirst() {
                    let text = try link.text()
                    let pattern = "\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}"
                    if let range = text.range(of: pattern, options: .regularExpression) {
                        let deadline = String(text[range])
                        let assignmentName = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                        results.append((assignmentName, deadline))
                    }
                }
            } catch {
                throw error
            }
        }
        //print("Results: \(results)")
        return results
    }*/
}

extension ManabaScraper {
    func scrapeTaskDataFromManaba(urlList: [String], cookieString: String) async throws -> [TaskData] {
        var taskInformationList: [TaskData] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for url in urlList {
            guard let url = URL(string: url) else {
                throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
            }
            
            var request = URLRequest(url: url)
            request.addValue(cookieString, forHTTPHeaderField: "Cookie")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let htmlContent = String(data: data, encoding: .utf8) ?? ""
            //print("タスクのHTML")
            //print(htmlContent)
            let doc: Document = try SwiftSoup.parse(htmlContent)
            let rows: Elements = try doc.select("#container > div.pagebody > div > table.stdlist tbody tr")
            print("Rows count: \(rows.size())")
            
            for row in rows.array() {
                // 各要素を取得しようとする前に、行のHTMLをプリントして確認
                //print("Row HTML: \(try row.outerHtml())")
                
                // 各要素の取得試み
                let taskNameElement = try row.select("h3.myassignments-title > a").first()
                let dueDateElement = try row.select("td:nth-child(3)").first()
                let belongedClassElement = try row.select("td:nth-child(2)").first()
                let taskURLElement = try row.select("td h3.myassignments-title a").first()
    
                // ここで if let ブロックを使用して、すべての要素が存在する場合のみ処理を続ける
                if let taskNameElement = taskNameElement, let dueDateElement = dueDateElement, let belongedClassElement = belongedClassElement, let taskURLElement = taskURLElement {
                    let taskName = try taskNameElement.text()
                    let dueDateString = try dueDateElement.text()
                    let belongedClassName = try belongedClassElement.text()
                    let taskURL = try taskURLElement.attr("href")
                    
                    if let dueDate = dateFormatter.date(from: dueDateString) {
                        // dueDateの1時間前を計算
                        let notificationTiming = Calendar.current.date(byAdding: .hour, value: -1, to: dueDate)
                        
                        if let taskId = extractTaskId(from: taskURL) { // taskIdを安全にアンラップ
                            let taskInfo = TaskData(
                                taskName: taskName,
                                dueDate: dueDate,
                                belongedClassName: belongedClassName,
                                taskURL: taskURL,
                                hasSubmitted: false, // 仮の値
                                notificationTiming: notificationTiming != nil ? [notificationTiming!] : nil, // 通知タイミングはdueDateの1時間前
                                taskId: taskId
                            )
                            taskInformationList.append(taskInfo)
                            print("Current list size: \(taskInformationList.count)")
                        } else {
                            print("Invalid task URL: \(taskURL)")
                        }
                    }
                    
                }
            }
        }
        print("タスクの中身ここから")
        print("Final list size: \(taskInformationList.count)")
        for taskInfo in taskInformationList {
            let formattedDueDate = dateFormatter.string(from: taskInfo.dueDate)
            let formattedNotificationTiming = taskInfo.notificationTiming?.first.map { dateFormatter.string(from: $0) } ?? "未設定"
            print("""
                   Final Task Info:
                   Task Name: \(taskInfo.taskName),
                   DueDate: \(formattedDueDate),
                   Class Name: \(taskInfo.belongedClassName),
                   Task URL: \(taskInfo.taskURL),
                   Has Submitted: \(taskInfo.hasSubmitted ? "Yes" : "No"),
                   Notification Timing: \(formattedNotificationTiming),
                   Task ID: \(taskInfo.taskId)
                   """)
        }
        
        return taskInformationList
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
   
    struct CellIndex: Hashable {
        let row: Int
        let column: Int
    }
    /*
    func getRegisteredClassDataFromManaba(urlString: String, cookieString: String) async throws -> [ClassInformation] {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.addValue(cookieString, forHTTPHeaderField: "Cookie")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let htmlContent = String(data: data, encoding: .utf8) ?? ""
        
        print("HTMLここから")
        print(htmlContent)
        print("HTMLここまで")
        
        // HTMLコンテンツが予期しないログインページであるかどうかをチェック
        if htmlContent.contains("ウェブログインサービス - 過去のリクエスト") {
            // UserDefaultsをクリア
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            UserDefaults.standard.synchronize()
            // エラーを投げて処理を中断
            throw NSError(domain: "ログインエラーページを検出", code: -2, userInfo: nil)
        }
        
        let doc: Document = try SwiftSoup.parse(htmlContent)
        let rows: Elements = try doc.select("#courselistweekly > table > tbody > tr")
        
        var classInformationList: [ClassInformation] = []
        var shiftBag: [CellIndex: Int] = [:] // shiftBagの型をCellIndexを使って更新
        
        for (i, row) in rows.array().enumerated() {
            if i == 0 { continue }
            
            let cells = try row.select("td").array()
            //var shiftNum = 0
            
            for (j, cell) in cells.enumerated() {
                if j == 0 { continue }
                
                let currentIndex = CellIndex(row: i, column: j) // 現在のセルのインデックス
                let shiftNum = shiftBag[currentIndex, default: 0] // CellIndexをキーとしてshiftNumを取得
                
                // rowspanの処理
                let rowspanValue = try cell.attr("rowspan")
                var additionalRows = 1 // rowspanによって追加される行の数
                if let rowspan = Int(rowspanValue), rowspan > 1 {
                    additionalRows = rowspan
                    for k in 1..<rowspan {
                        for columnToUpdate in j..<cells.count {
                            let affectedIndex = CellIndex(row: i + k, column: columnToUpdate)
                            shiftBag[affectedIndex, default: 0] += 1
                        }
                    }
                }
                print(i,"行目",j,"列目","shiftNum\(shiftNum)")
                
                
                let divs = try cell.select("div > div > div")
                let divs2 = try cell.select("div > a:nth-child(1)")
                let divs3 = try cell.select("div > a:nth-child(1)").first()
                
                /*if let classRoom = try divs.first()?.text(), let classNameElement = try divs2.first()?.select("a").first(), let classURL = try divs3?.attr("href") {
                 let className = try classNameElement.text()
                 for k in 0..<additionalClasses {
                 let classPeriod = (7 * (i - 1 + shiftNum + k) + j - 1) // 時間枠を考慮したID計算
                 let classInfo = ClassInformation(
                 id: "\(classPeriod)", // shiftNumと追加される授業回数を反映
                 name: className,
                 room: classRoom,
                 url: classURL,
                 professorName: "",
                 classIdChangeable: false
                 )
                 classInformationList.append(classInfo)
                 }*/
                if let classRoom = try divs.first()?.text(), let classNameElement = try divs2.first()?.select("a").first(), let classURL = try divs3?.attr("href") {
                    let className = try classNameElement.text()
                    
                    // rowspanがある場合、指定された回数だけ同じ授業情報を追加
                    for additionalRow in 0..<additionalRows {
                        let nextRowIndex = i + additionalRow
                        let classPeriod = (7 * (nextRowIndex - 1)) + j - 1 + shiftNum // 時間枠を考慮したID計算
                        let classInfo = ClassInformation(
                            id: "\(classPeriod)",
                            name: className,
                            room: classRoom,
                            url: classURL,
                            professorName: "",
                            classIdChangeable: false
                        )
                        classInformationList.append(classInfo)
                    }
                }
            }
        }
        
        classInformationList.sort { (classInfo1, classInfo2) -> Bool in
            guard let id1 = Int(classInfo1.id), let id2 = Int(classInfo2.id) else {
                // IDの変換に失敗した場合は、元の順序を保持するためにfalseを返す
                // 実際には、変換に失敗することが想定外の場合、適切なエラーハンドリングが必要
                return false
            }
            return id1 < id2
        }
        print("classInfoの中身")
        
        for classInfo in classInformationList {
            
            print("\(classInfo.id)???\(classInfo.name)???\(classInfo.room)???\(classInfo.url)")
        }
        return classInformationList
    }
     */
    /*
    func getRegisteredClassDataFromManaba(urlString: String, cookieString: String) async throws -> [ClassInformation] {
        var classInformationList: [ClassInformation] = []

        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }

        var request = URLRequest(url: url)
        request.addValue(cookieString, forHTTPHeaderField: "Cookie")

        let (data, _) = try await URLSession.shared.data(for: request)
        let html = String(data: data, encoding: .utf8) ?? ""

        print("HTML（get）ここから")
        print(html)
        print("HTMLここまで")

        // HTMLコンテンツが予期しないログインページであるかどうかをチェック
        if html.contains("ウェブログインサービス - 過去のリクエスト") {
            // UserDefaultsをクリア
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            UserDefaults.standard.synchronize()
            // エラーを投げて処理を中断
            throw NSError(domain: "ログインエラーページを検出", code: -2, userInfo: nil)
        }

        let doc = try SwiftSoup.parse(html)
        let rows = try doc.select("#container > div.pagebody > div > div.contentbody-left > div.my-infolist.my-infolist-mycourses > div.mycourses-body > div > table > tbody tr")

        classInformationList.removeAll()

        for row in rows.array() {
            let cells = try row.select("td")

            if cells.size() > 4 {  // Ensure there are enough cells to extract all data
                let nameElement = try? cells.get(0).select("td:nth-child(1)").first()
                let urlElement = try? cells.get(0).select("td:nth-child(1) > span > a[href]").first()
                let roomElement = try? cells.get(2).select("td:nth-child(3)").first()
                let dayAndPeriodElement = try? cells.get(2).select("td:nth-child(3) > span").first()
                let professorNameElement = try? cells.get(3).select("td:nth-child(4)").first()

                guard let name = try? nameElement?.text(),
                      let url = try? urlElement?.attr("href"),
                      let room = try? roomElement?.text(),
                      let dayAndPeriod = try? dayAndPeriodElement?.text(),
                      let professorName = try? professorNameElement?.text() else {
                    continue
                }

                if let classId = extractTaskId(from: url) {
                    let classInformation = ClassInformation(
                        classId: classId,
                        dayAndPeriod: dayAndPeriod,
                        name: name,
                        room: room,
                        url: url,
                        professorName: professorName,
                        classIdChangeable: false,  // Set based on some condition if applicable
                        isNotifying: true
                    )
                    classInformationList.append(classInformation)
                } else {
                    print("Invalid task URL: \(url)")
                }
            }
        }

        classInformationList.sort { (classInfo1, classInfo2) -> Bool in
            guard let id1 = Int(classInfo1.dayAndPeriod), let id2 = Int(classInfo2.dayAndPeriod) else {
                // IDの変換に失敗した場合は、元の順序を保持するためにfalseを返す
                // 実際には、変換に失敗することが想定外の場合、適切なエラーハンドリングが必要
                return false
            }
            return id1 < id2
        }

        print("classInfoの中身")
        for classInfo in classInformationList {
            print("\(classInfo.classId)???\(classInfo.dayAndPeriod)???\(classInfo.name)???\(classInfo.room)???\(classInfo.url)")
        }

        return classInformationList
    }*/
    func getRegisteredClassDataFromManaba(urlString: String, cookieString: String) async throws -> [ClassData] {
        var classInformationList: [ClassData] = []

        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }

        var request = URLRequest(url: url)
        request.addValue(cookieString, forHTTPHeaderField: "Cookie")

        let (data, _) = try await URLSession.shared.data(for: request)
        let html = String(data: data, encoding: .utf8) ?? ""

        //print("HTML（get）ここから")
        //print(html)
        //print("HTMLここまで")

        // HTMLコンテンツが予期しないログインページであるかどうかをチェック
        if html.contains("ウェブログインサービス - 過去のリクエスト") {
            // UserDefaultsをクリア
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            UserDefaults.standard.synchronize()
            // エラーを投げて処理を中断
            throw NSError(domain: "ログインエラーページを検出", code: -2, userInfo: nil)
        }

        let doc = try SwiftSoup.parse(html)
        let rows = try doc.select("#courselistweekly tr:not(.title)") // ヘッダー行を除外

        classInformationList.removeAll()

        for row in rows {
            let cells = try row.select("td.course-cell")

            for cell in cells {
                let nameElement = try? cell.select("a").first()
                let urlElement = try? cell.select("a").first()
                let dayAndPeriodElement = try? cell.select(".couraselocationinfo").first()

                guard let name = try? nameElement?.text(),
                      let url = try? urlElement?.attr("href"),
                      let dayAndPeriodText = try? dayAndPeriodElement?.text() else {
                    continue
                }

                let dayAndPeriod = convertDayAndPeriod(dayAndPeriodText: dayAndPeriodText)
                let room = dayAndPeriodText // 部屋情報は dayAndPeriodText の一部と仮定
                let professorName = "Unknown" // 教授名は提供されたHTMLスニペットに含まれていない

                if let classId = extractTaskId(from: url) {
                    let classInformation = ClassData(
                        classId: classId,
                        dayAndPeriod: dayAndPeriod,
                        name: name,
                        room: room,
                        url: url,
                        professorName: professorName,
                        classIdChangeable: false,  // 必要に応じて条件に基づいて設定
                        isNotifying: true
                    )
                    classInformationList.append(classInformation)
                } else {
                    print("Invalid task URL: \(url)")
                }
            }
        }

        classInformationList.sort { (classInfo1, classInfo2) -> Bool in
            return classInfo1.dayAndPeriod < classInfo2.dayAndPeriod
        }

        print("classInfoの中身")
        for classInfo in classInformationList {
            print("\(classInfo.classId)???\(classInfo.dayAndPeriod)???\(classInfo.name)???\(classInfo.room)???\(classInfo.url)???\(classInfo.professorName)")
        }

        return classInformationList
    }
    /*
    func convertDayAndPeriod(dayAndPeriodText: String) -> Int {
        let dayMapping = ["月": 0, "火": 1, "水": 2, "木": 3, "金": 4, "土": 5, "日": 6]
        
        let day = String(dayAndPeriodText.prefix(1))
        let periodText = String(dayAndPeriodText.dropFirst())
        let period = Int(periodText) ?? 1
        print(dayAndPeriodText)
        print("dayの値")
        print(day)
        print("periodの値")
        print(period)
        if let dayValue = dayMapping[day] {
            return dayValue + (period - 1) * 7
        } else {
            return -1 // 日が認識されない場合は無効な値を返す
        }
    }
     */
    func convertDayAndPeriod(dayAndPeriodText: String) -> Int {
        let dayMapping = ["月": 0, "火": 1, "水": 2, "木": 3, "金": 4, "土": 5, "日": 6]

        let pattern = "([月火水木金土日])(\\d)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = dayAndPeriodText as NSString
            if let match = regex.firstMatch(in: dayAndPeriodText, options: [], range: NSRange(location: 0, length: nsString.length)) {
                let day = nsString.substring(with: match.range(at: 1))
                let periodText = nsString.substring(with: match.range(at: 2))
                let period = Int(periodText) ?? 1

                print(dayAndPeriodText)
                print("dayの値")
                print(day)
                print("periodの値")
                print(period)

                if let dayValue = dayMapping[day] {
                    return dayValue + (period - 1) * 7
                }
            }
        }
        return -1 // 日が認識されない場合は無効な値を返す
    }



    /*
    func getRegisteredClassDataFromManaba(urlString: String, cookieString: String) async throws -> [ClassInformation] {
        var classInformationList: [ClassInformation] = []

        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.addValue(cookieString, forHTTPHeaderField: "Cookie")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let html = String(data: data, encoding: .utf8) ?? ""
        
        print("HTML（get）ここから")
        print(html)
        print("HTMLここまで")
        
        // HTMLコンテンツが予期しないログインページであるかどうかをチェック
        if html.contains("ウェブログインサービス - 過去のリクエスト") {
            // UserDefaultsをクリア
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            UserDefaults.standard.synchronize()
            // エラーを投げて処理を中断
            throw NSError(domain: "ログインエラーページを検出", code: -2, userInfo: nil)
        }
        
        let doc = try SwiftSoup.parse(html)
        let rows = try doc.select("#container > div.pagebody > div > div.contentbody-left > div.my-infolist.my-infolist-mycourses > div.mycourses-body > div > table > tbody tr")
        
        for row in rows.array() {
            let cells = try row.select("td")
            if cells.size() > 4 {  // Ensure there are enough cells to extract all data
                let name = try cells.get(0).text()
                let url = try cells.get(0).select("span > a[href]").attr("href")
                let room = try cells.get(2).text()
                let professorName = try cells.get(3).text()
                let dayAndPeriod = try cells.get(4).text()  // Assuming this is the correct column for the class ID

                if let classId = extractTaskId(from: url) {
                    let classInformation = ClassInformation(
                        classId: classId,
                        dayAndPeriod: dayAndPeriod,
                        name: name,
                        room: room,
                        url: url,
                        professorName: professorName,
                        classIdChangeable: false,  // Set based on some condition if applicable
                        isNotifying: true
                    )
                    classInformationList.append(classInformation)
                } else {
                    print("Invalid task URL: \(url)")
                }
            }
        }
        
        classInformationList.sort { (classInfo1, classInfo2) -> Bool in
            guard let id1 = Int(classInfo1.dayAndPeriod), let id2 = Int(classInfo2.dayAndPeriod) else {
                // IDの変換に失敗した場合は、元の順序を保持するためにfalseを返す
                // 実際には、変換に失敗することが想定外の場合、適切なエラーハンドリングが必要
                return false
            }
            return id1 < id2
        }
        print("classInfoの中身")
        
        for classInfo in classInformationList {
            
            print("\(classInfo.classId)???\(classInfo.dayAndPeriod)???\(classInfo.name)???\(classInfo.room)???\(classInfo.url)")
        }
        
        return classInformationList
    }*/
        
    func getUnRegisteredClassDataFromManaba(urlString: String, cookieString: String) async throws -> [UnregisteredClassInformation] {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.addValue(cookieString, forHTTPHeaderField: "Cookie")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let htmlContent = String(data: data, encoding: .utf8) ?? ""
        let doc: Document = try SwiftSoup.parse(htmlContent)
        let rows: Elements = try doc.select("#courselistweekly > div > table > tbody > tr")
        
        var classInformationList: [UnregisteredClassInformation] = []
        
        for row in rows.array() {
            let cells = try row.select("td")
            
            let divs = try cells.select("td:nth-child(1)")
            let divs2 = try cells.select("td.center")
            let divs3 = try cells.select("td:nth-child(3)")
            let divs4 = try cells.select("td:nth-child(4)")
            let divs5 = try cells.select("td:nth-child(1) > span > a[href]")
            
            let classURL = try? divs5.attr("href")
            
            if let className = try divs.first()?.text(),
               let year = try divs2.first()?.text(),
               let classRoom = try divs3.first()?.text(),
               let professorName = try divs4.first()?.text(),
               let classURL = classURL,
               !className.isEmpty && !year.isEmpty && !classRoom.isEmpty && !professorName.isEmpty && !classURL.isEmpty {
                if let classId = extractTaskId(from: classURL) {
                    let classInfo = UnregisteredClassInformation(classId: classId, name: className, professorName: professorName, url: classURL)
                        classInformationList.append(classInfo)
                    } else {
                        print("Error: Could not extract classId from URL \(classURL)")
                    }
            }
        }
        /*
         // スクレイピング処理の直前でclassInformationListの中身をプリント
         for classInfo in classInformationList {
         print("Name: \(classInfo.name), Professor Name: \(classInfo.professorName), URL: \(classInfo.url)")
         }
         */
        return classInformationList
    }
    // TODO: URLとclassId追加？
    func getProfessorNameFromManaba(urlString: String, cookieString: String) async throws -> [ClassAndProfessor] {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.addValue(cookieString, forHTTPHeaderField: "Cookie")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let htmlContent = String(data: data, encoding: .utf8) ?? ""
        let doc: Document = try SwiftSoup.parse(htmlContent)
        let rows: Elements = try doc.select("#container > div.pagebody > div > div.contentbody-left > div.my-infolist.my-infolist-mycourses > div.mycourses-body > div > table > tbody > tr")
        
        var classAndProfessors: [ClassAndProfessor] = []
        
        for row in rows.array() {
            let div1 = try row.select("td:nth-child(1) > span > a").first()
            let div2 = try row.select("td:nth-child(4)").first()
            
            if let className = try div1?.text(), let professorName = try div2?.text(), !className.isEmpty, !professorName.isEmpty {
                classAndProfessors.append(ClassAndProfessor(className: className, professorName: professorName))
            }
        }
        /*
         // リターンの直前でリストの中身を確認
         for classAndProfessor in classAndProfessors {
         print("Class Name: \(classAndProfessor.className), Professor Name: \(classAndProfessor.professorName)")
         }
         */
        return classAndProfessors
    }
}


