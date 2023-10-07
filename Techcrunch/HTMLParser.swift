//
//  HTMLParser.swift
//  Techcrunch
//
//  Created by 鈴木悠太 on 2023/05/18.
//

import SwiftSoup
import Foundation
import WebKit

final class HTMLParser {
    private let cookieString: String

    init(cookiestring: String){
        self.cookieString = cookiestring
    }

    // ManabaのHTML文字列を受け取り，課題の情報の文字列を返す関数
    func parse() async throws -> [String] {
        let targetUrls = [
            "https://ct.ritsumei.ac.jp/ct/home_summary_query",
            "https://ct.ritsumei.ac.jp/ct/home_summary_survey",
            "https://ct.ritsumei.ac.jp/ct/home_summary_report"
        ]
        
        var results = [String]()
        for targetUrl in targetUrls {
            var request = URLRequest(url: URL(string: targetUrl)!)
            request.httpMethod = "GET"
            request.addValue(self.cookieString, forHTTPHeaderField: "Cookie")
            let (data, _) = try await URLSession.shared.data(for: request)
            print("Received data:\n\(String(data: data, encoding: .utf8) ?? "")")

            var result = "first"
            
            do {
                let doc: Document = try SwiftSoup.parse(String(data: data, encoding: .utf8) ?? "")
                let links: Elements = try doc.select("#container > div.pagebody > div > table.stdlist tbody tr")
                for link in links.dropFirst(){
                    print("ヴィンヴィfにインフィニい")
                    print(links)
                    //("#container > div.pagebody > div > table > tbody")
                    result = try link.text()
                    print(result)
                    results.append(result)
                }
            } catch Exception.Error(let type, let message) {
                print(type)
                print(message)
                throw NSError(domain: "Failed to scrape", code: -1, userInfo: nil)
            } catch {
                throw error
            }
            print("---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
            
        }
        return results
    }

}

extension HTMLParser {

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
        /*for row in rows {
            let cells: Elements = try row.select("td")
            for i in 1..<cells.count {
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
        }*/
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
    }
}

