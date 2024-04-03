//
//  HTMLParser.swift
//  Techcrunch
//
//  Created by 鈴木悠太 on 2023/05/18.
//

import SwiftSoup
import Foundation
import WebKit

struct TaskInformation {
    var taskName: String
    var dueDate: Date // 日付型で期限を保持
    var belongedClassName: String
    var taskURL: String
    var hasSubmitted: Bool // 提出済みかどうかのフラグ
    var notificationTiming: [Date]? // 通知タイミングとして複数の日時を持つ
    var taskId: Int // タスクID
}

struct ClassInformation {
    var id: String
    var name: String
    var room: String
    var url: String
    var professorName: String
    var classIdChangeable: Bool
}

struct UnregisteredClassInformation {
    var name: String
    var professorName: String
    var url: String
}

struct ClassAndProfessor {
    var className: String
    var professorName: String
}

final class ManabaScraper {
    private let cookieString: String
    var classInformation: [ClassInformation] = []

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
        print("Results: \(results)")
        return results
    }
}

extension ManabaScraper {
    func scrapeTaskDataFromManaba(urlList: [String], cookieString: String) async throws -> [TaskInformation] {
        var taskInformationList: [TaskInformation] = []
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
                print("Row HTML: \(try row.outerHtml())")
                
                // 各要素の取得試み
                let taskNameElement = try row.select("h3.myassignments-title > a").first()
                let dueDateElement = try row.select("td:nth-child(3)").first()
                let belongedClassElement = try row.select("td:nth-child(2)").first()
                let taskURLElement = try row.select("td h3.myassignments-title a").first()
                
                // 各要素の存在確認と内容プリント
                if let taskName = taskNameElement {
                    print("Task Name Element: \(try taskName.text())")
                } else {
                    print("Task Name Element: not found")
                }
                
                if let dueDate = dueDateElement {
                    print("DueDate Element: \(try dueDate.text())")
                } else {
                    print("DueDate Element: not found")
                }
                
                if let belongedClass = belongedClassElement {
                    print("Belonged Class Element: \(try belongedClass.text())")
                } else {
                    print("Belonged Class Element: not found")
                }
                
                if let taskURL = taskURLElement {
                    print("Task URL Element: \(try taskURL.attr("href"))")
                } else {
                    print("Task URL Element: not found")
                }
                
                // ここで if let ブロックを使用して、すべての要素が存在する場合のみ処理を続ける
                if let taskNameElement = taskNameElement, let dueDateElement = dueDateElement, let belongedClassElement = belongedClassElement, let taskURLElement = taskURLElement {
                    let taskName = try taskNameElement.text()
                    let dueDateString = try dueDateElement.text()
                    let belongedClassName = try belongedClassElement.text()
                    let taskURL = try taskURLElement.attr("href")
                    
                    if let dueDate = dateFormatter.date(from: dueDateString) {
                        // dueDateの1時間前を計算
                        let notificationTiming = Calendar.current.date(byAdding: .hour, value: -1, to: dueDate)
                        
                        let taskInfo = TaskInformation(
                            taskName: taskName,
                            dueDate: dueDate,
                            belongedClassName: belongedClassName,
                            taskURL: taskURL,
                            hasSubmitted: false, // 仮の値
                            notificationTiming: notificationTiming != nil ? [notificationTiming!] : nil, // 通知タイミングはdueDateの1時間前
                            taskId: 0 // taskIdを1に設定
                        )
                        taskInformationList.append(taskInfo)
                        print("Current list size: \(taskInformationList.count)")
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
    /*
     func getRegisteredClassDataFromManaba(urlString: String, cookieString: String) async throws -> [ClassInformation] {
     guard let url = URL(string: urlString) else {
     throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
     }
     
     var request = URLRequest(url: url)
     request.addValue(cookieString, forHTTPHeaderField: "Cookie")
     
     let (data, _) = try await URLSession.shared.data(for: request)
     let htmlContent = String(data: data, encoding: .utf8) ?? ""
     print(htmlContent)
     //print("スクレイピング始めます")
     let doc: Document = try SwiftSoup.parse(htmlContent)
     let rows: Elements = try doc.select("#courselistweekly > table > tbody > tr")
     
     var classInformationList: [ClassInformation] = []
     
     for (i, row) in rows.array().enumerated() {
     // 最初の行をスキップ
     if i == 0 {
     continue
     }
     
     let cells = try row.select("td").array()
     for (j, cell) in cells.enumerated() {
     // 最初の列をスキップ
     if j == 0 {
     continue
     }
     /*
      let divs = try cell.select("div.couraselocationinfo.couraselocationinfoV2")
      let divs2 = try cell.select("div.courselistweekly-nonborder.courselistweekly-c")
      let divs3 = try cell.select("div.courselistweekly-nonborder.courselistweekly-c a[href]").first()
      */
     let divs = try cell.select("div > div > div")
     let divs2 = try cell.select("div > a:nth-child(1)")
     let divs3 = try cell.select("div > a:nth-child(1)").first()
     
     if let classRoom = try divs.first()?.text(), let classNameElement = try divs2.first()?.select("a").first(), let classURL = try divs3?.attr("href") {
     let className = try classNameElement.text()
     let classInfo = ClassInformation(id: "\(7 * (i - 1) + (j - 1))", name: className, room: classRoom, url: classURL, professorName: "", classIdChangeable: false)
     classInformationList.append(classInfo)
     }
     }
     }
     print("classInfoの中身")
     
     for classInfo in classInformationList {
     
     print("\(classInfo.id)???\(classInfo.name)???\(classInfo.room)???\(classInfo.url)")
     }
     
     return classInformationList
     }
     */
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
     let doc: Document = try SwiftSoup.parse(htmlContent)
     let rows: Elements = try doc.select("#courselistweekly > table > tbody > tr")
     
     var classInformationList: [ClassInformation] = []
     var shiftBag: [CellIndex: Int] = [:] // shiftBagの型をCellIndexを使って更新
     
     for (i, row) in rows.array().enumerated() {
     if i == 0 { continue }
     
     let cells = try row.select("td").array()
     var shiftNum = 0
     
     for (j, cell) in cells.enumerated() {
     if j == 0 { continue }
     
     let currentIndex = CellIndex(row: i, column: j)
     shiftNum += shiftBag[currentIndex, default: 0]
     
     let rowspanValue = try cell.attr("rowspan")
     if let rowspan = Int(rowspanValue), rowspan > 1 {
     for k in 1..<rowspan {
     let affectedIndex = CellIndex(row: i + k, column: j)
     shiftBag[affectedIndex] = (shiftBag[affectedIndex, default: 0]) + 1
     }
     }
     
     let divs = try cell.select("div > div > div")
     let divs2 = try cell.select("div > a:nth-child(1)")
     let divs3 = try cell.select("div > a:nth-child(1)").first()
     
     if let classRoom = try divs.first()?.text(), let classNameElement = try divs2.first()?.select("a").first(), let classURL = try divs3?.attr("href") {
     let className = try classNameElement.text()
     let classInfo = ClassInformation(
     id: "\(7 * (i - 1 + shiftNum) + j - 1)", // shiftNumを反映
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
                    let classInfo = UnregisteredClassInformation(name: className, professorName: professorName, url: classURL)
                    classInformationList.append(classInfo)
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
    

