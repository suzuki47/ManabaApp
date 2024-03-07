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
    var deadline: String
    var belongedClassName: String
    var taskURL: String
}

struct ClassInformation {
    var id: String
    var name: String
    var room: String
    var url: String
    var professorName: String
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
    /*
    func fetchClassroomInfo(usingCookie cookieString: String) async throws -> [String] {
        var classroomInfo = [String]()

        let targetUrl = "https://ct.ritsumei.ac.jp/ct/home_course"
        var request = URLRequest(url: URL(string: targetUrl)!)
        request.httpMethod = "GET"
        request.addValue(cookieString, forHTTPHeaderField: "Cookie")
        let (data, _) = try await URLSession.shared.data(for: request)

        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "Failed to convert data to string", code: -1, userInfo: nil)
        }

        let doc: Document = try SwiftSoup.parse(html)
        let doc2: Elements = try doc.select("#courselistweekly > table > tbody")

        let rows: Elements = try doc2.select("tr")
        
        for row in rows {
            let cells: Elements = try row.select("td")
            let start = min(1, cells.count)
            let end = cells.count
            for i in start..<end {
                let cell: Element = try cells.get(i)
                let divs: Elements = try cell.select("div.couraselocationinfo.couraselocationinfoV2")
                let divs2: Elements = try cell.select("div.courselistweekly-nonborder.courselistweekly-c")

                if divs.count > 0 {
                    let text = try divs.first()!.text()
                    let text2 = try divs2.first()!.text()
                    classroomInfo.append(text)
                    classroomInfo.append(text2)
                }
            }
        }

        /*print("classroom: \(html)")*/
        print("classroom: \(classroomInfo)")
        print("取得した授業情報: \(classroomInfo)")
        return classroomInfo
    }*/
    /*
    func fetchClassroomInfo(usingCookie cookieString: String) async throws -> [(String, String)] {
        let targetUrl = "https://ct.ritsumei.ac.jp/ct/home_course?chglistformat=list"
        var request = URLRequest(url: URL(string: targetUrl)!)
        request.httpMethod = "GET"
        request.addValue(cookieString, forHTTPHeaderField: "Cookie")
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "Failed to convert data to string", code: -1, userInfo: nil)
        }
        
        print("html全部:\(html)")
        
        let doc: Document = try SwiftSoup.parse(html)
        let rows: Elements = try doc.select("#container > div.pagebody > div > div.contentbody-left > div.my-infolist.my-infolist-mycourses > div.mycourses-body > div > table > tbody > tr:nth-child(3) > td:nth-child(1) > span")
        
        var classroomInfo = [(String, String)]()
        for row in rows {
            let cells: Elements = try row.select("td")
            // 配列のインデックスは0から始まるため、startは0になります。
            let start = 0
            let end = cells.size()
            for i in start..<end {
                let cell: Element = try cells.get(i)
                let locationDiv: Elements = try cell.select("div.couraselocationinfo.couraselocationinfoV2")
                let classDiv: Elements = try cell.select("div.courselistweekly-nonborder.courselistweekly-c")
                
                if let locationText = try? locationDiv.text(),
                   let classText = try? classDiv.text() {
                    // 教室名と授業名のタプルを配列に追加します。
                    classroomInfo.append((classText, locationText))
                }
            }
        }
        print("取得した授業情報（ManabaScraper）: \(classroomInfo)")
        return classroomInfo
    }*/
    func scrapeTaskDataFromManaba(urlList: [String], cookieString: String) async throws -> [TaskInformation] {
        var taskInformationList: [TaskInformation] = []

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
                let deadlineElement = try row.select("td:nth-child(3)").first()
                let belongedClassElement = try row.select("td:nth-child(2)").first()
                let taskURLElement = try row.select("td h3.myassignments-title a").first()

                // 各要素の存在確認と内容プリント
                if let taskName = taskNameElement {
                    print("Task Name Element: \(try taskName.text())")
                } else {
                    print("Task Name Element: not found")
                }

                if let deadline = deadlineElement {
                    print("Deadline Element: \(try deadline.text())")
                } else {
                    print("Deadline Element: not found")
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
                if let taskNameElement = taskNameElement, let deadlineElement = deadlineElement, let belongedClassElement = belongedClassElement, let taskURLElement = taskURLElement {
                    let taskName = try taskNameElement.text()
                    let deadline = try deadlineElement.text()
                    let belongedClassName = try belongedClassElement.text()
                    let taskURL = try taskURLElement.attr("href")
                    
                    // ここでデータを TaskInformation に追加
                    let taskInfo = TaskInformation(taskName: taskName, deadline: deadline, belongedClassName: belongedClassName, taskURL: taskURL)
                    taskInformationList.append(taskInfo)
                    print("Current list size: \(taskInformationList.count)")
                }
            }

        }
        print("タスクの中身ここから")
        print("Final list size: \(taskInformationList.count)")
        for taskInfo in taskInformationList {
            print("Final Task Info: Task Name: \(taskInfo.taskName), Deadline: \(taskInfo.deadline), Class Name: \(taskInfo.belongedClassName), Task URL: \(taskInfo.taskURL)")
        }


        return taskInformationList
    }
    
    func getRegisteredClassDataFromManaba(urlString: String, cookieString: String) async throws -> [ClassInformation] {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.addValue(cookieString, forHTTPHeaderField: "Cookie")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let htmlContent = String(data: data, encoding: .utf8) ?? ""
        //print(htmlContent)
        print("スクレイピング始めます")
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
                
                let divs = try cell.select("div.couraselocationinfo.couraselocationinfoV2")
                let divs2 = try cell.select("div.courselistweekly-nonborder.courselistweekly-c")
                let divs3 = try cell.select("div.courselistweekly-nonborder.courselistweekly-c a[href]").first()
                
                if let classRoom = try divs.first()?.text(), let classNameElement = try divs2.first()?.select("a").first(), let classURL = try divs3?.attr("href") {
                    let className = try classNameElement.text()
                    let classInfo = ClassInformation(id: "\(7 * (i - 1) + (j - 1))", name: className, room: classRoom, url: classURL, professorName: "")
                    classInformationList.append(classInfo)
                }
            }
        }
        
        
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
        // スクレイピング処理の直前でclassInformationListの中身をプリント
        for classInfo in classInformationList {
            print("Name: \(classInfo.name), Professor Name: \(classInfo.professorName), URL: \(classInfo.url)")
        }
        
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

        // リターンの直前でリストの中身を確認
        for classAndProfessor in classAndProfessors {
            print("Class Name: \(classAndProfessor.className), Professor Name: \(classAndProfessor.professorName)")
        }
        
        return classAndProfessors
    }
    
    /*
    func fetchClassData(urlString: String, cookieString: String) async throws {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.addValue(cookieString, forHTTPHeaderField: "Cookie")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let htmlContent = String(data: data, encoding: .utf8) ?? ""
            //print("とりまHTML")
            //print(htmlContent)
            print("スクレイピング始めます")
            let doc: Document = try SwiftSoup.parse(htmlContent)
            let rows: Elements = try doc.select("#courselistweekly > table > tbody > tr")
            print("セルのプリント")
            for row in rows.array() {
                let cells = try row.select("td").array()
                for cell in cells {
                    // ここで各セルの内容を取り扱います。
                    
                    print(try cell.text())
                }
            }
        } catch {
            // ここでエラーをキャッチして適切に処理します。
            print("Error fetching data: \(error.localizedDescription)")
            throw error
        }
    }
     */
}

