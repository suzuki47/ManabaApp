//
//  HTMLParser.swift
//  Techcrunch
//
//  Created by 鈴木悠太 on 2023/05/18.
//

import SwiftSoup
import Foundation
import WebKit

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


