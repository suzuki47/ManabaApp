//
//  ClassData.swift
//  Techcrunch
//
//  Created by 鈴木悠太 on 2023/08/16.
//

import Foundation

// 仮定するClassDataクラスの実装
class ClassData {
    static var classData: [[ClassData]] = Array(repeating: Array(repeating: ClassData(), count: 7), count: 7)
    var className: String
    var classRoom: String
    
    var description: String {
        return "\(className) \(classRoom)".trimmingCharacters(in: .whitespaces)
    }

    init(className: String = "次は空きコマです。", classRoom: String = "") {
        self.className = className
        self.classRoom = classRoom
    }

    static func setClassData(_ data: ClassData, forDay dayIndex: Int, period: Int) {
        self.classData[dayIndex][period - 1] = data
    }
    
}


// 解析と保存を行う関数
func parseAndStoreClassData(dataList: [String]) {
    let dayIndexMap: [String: Int] = ["月": 0, "火": 1, "水": 2, "木": 3, "金": 4, "土": 5, "日": 6]

    ClassData.classData = Array(repeating: Array(repeating: ClassData(), count: 7), count: 7)

    for item in dataList {
        // § 記号で区切られた複数の授業情報を個別に処理
        let classesInfo = item.components(separatedBy: " § ")
        for classInfo in classesInfo {
            // 曜日と時限の情報を抽出
            let regexPattern = "(月|火|水|木|金|土|日)(\\d):"
            guard let regex = try? NSRegularExpression(pattern: regexPattern),
                  let match = regex.firstMatch(in: classInfo, range: NSRange(classInfo.startIndex..., in: classInfo)) else { continue }
            
            let dayRange = Range(match.range(at: 1), in: classInfo)!
            let periodRange = Range(match.range(at: 2), in: classInfo)!
            let dayString = String(classInfo[dayRange])
            let periodString = String(classInfo[periodRange])

            // 教室情報を抽出
            guard let roomMatch = classInfo.range(of: ":\\s*\\w+$", options: .regularExpression) else { continue }
            let room = String(classInfo[roomMatch]).split(separator: ":").map(String.init).last!.trimmingCharacters(in: .whitespaces)

            // 授業名を抽出
            let classNameRegexPattern = "^(.*?)\\s+\\w+:"
            guard let classNameRegex = try? NSRegularExpression(pattern: classNameRegexPattern),
                  let classNameMatch = classNameRegex.firstMatch(in: classInfo, range: NSRange(classInfo.startIndex..., in: classInfo)) else { continue }
            let classNameRange = Range(classNameMatch.range(at: 1), in: classInfo)!
            let className = String(classInfo[classNameRange]).trimmingCharacters(in: .whitespacesAndNewlines)

            guard let dayIndex = dayIndexMap[dayString],
                  let period = Int(periodString) else { continue }

            let classData = ClassData(className: className, classRoom: room)
            ClassData.setClassData(classData, forDay: dayIndex, period: period)
        }
    }
}



/*import Foundation

class ClassData {
    static var classData: [[ClassData]] = []
    var className: String
    var classRoom: String
    var nextTiming: Date?
    var judge: Bool

    init() {
        self.className = "次は空きコマです。"
        self.classRoom = ""
        self.nextTiming = nil
        self.judge = false
    }

    static func setClassData(_ classData: ClassData, num: Int) {
        self.classData[num].append(classData)
    }

    static func getInfor() -> ClassData {
        let now = Date()
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: now) // 1: Sunday, 2: Monday, ...
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let totalMinutes = hour * 60 + minute

        var row: Int
        switch dayOfWeek {
        case 2: // Monday
            row = 0
        case 3: // Tuesday
            row = 1
        case 4: // Wednesday
            row = 2
        case 5: // Thursday
            row = 3
        case 6: // Friday
            row = 4
        default: // Saturday, Sunday, or other
            return ClassData() // Return empty class data if it's a non-class day
        }

        var line: Int
        switch totalMinutes {
        case 540...630: // 9:00 - 10:30
            line = 0
        case 640...730: // 10:40 - 12:10
            line = 1
        case 780...870: // 13:00 - 14:30
            line = 2
        case 880...970: // 14:40 - 16:10
            line = 3
        case 980...1070: // 16:20 - 17:50
            line = 4
        case 1080...1170: // 18:00 - 19:30
            line = 5
        case 1180...1290: // 19:40 - 21:10
            line = 6
        default:
            return ClassData() // Return empty class data if it's outside of class hours
        }

        print("今見たのは\(row)曜日\(line)時間目")
        // Ensure the `classData` array is properly initialized and populated to avoid index out of range errors
        if classData.indices.contains(row) && classData[row].indices.contains(line) {
            return classData[row][line]
        } else {
            return ClassData() // Return empty class data if there is no data for the current time slot
        }
    }

}*/
//教室の情報をどのように格納するか聞く
// 授業データを解析してClassDataオブジェクトを返す関数
/*func parseAndStoreClassData(dataList: [String]) {
    // 曜日をインデックスに変換する辞書
    let dayIndexMap: [String: Int] = ["月": 0, "火": 1, "水": 2, "木": 3, "金": 4, "土": 5, "日": 6]
    // ClassData配列を初期化（5日分、各日7時限分）
    ClassData.classData = Array(repeating: Array(repeating: ClassData(), count: 7), count: 7)

    for item in dataList {
        // § 記号があるデータは無視
        guard !item.contains("§") else { continue }
        // 時限と教室の情報のみ抽出
        guard let match = item.range(of: "(\\w+)(\\d+):(\\w+)", options: .regularExpression) else { continue }
        
        let details = String(item[match])
        let components = details.components(separatedBy: ":")
        
        if components.count == 2, let dayChar = components[0].first, let period = Int(components[0].dropFirst()), let dayIndex = dayIndexMap[String(dayChar)] {
            let room = components[1]
            // 授業名を抽出（授業コードは無視）
            guard let nameMatch = item.range(of: ":(.+?)\\s", options: .regularExpression) else { continue }
            let className = String(item[nameMatch]).trimmingCharacters(in: CharacterSet(charactersIn: ": "))

            // ClassDataオブジェクトを作成
            let classData = ClassData()
            classData.className = className
            classData.classRoom = room
            
            // 対応する曜日と時限の場所にClassDataオブジェクトを格納
            ClassData.setClassData(classData, num: dayIndex * 7 + period - 1)
        }
    }
}*/
//setClassData関数を使用してデータをclassData配列に格納します
/*extension ClassData {
    // 指定されたインデックスの位置にClassDataオブジェクトを設定
    static func setClassData(_ classData: ClassData, num: Int) {
        let dayIndex = num / 7
        let periodIndex = num % 7
        self.classData[dayIndex][periodIndex] = classData
    }
}*/










/*import Foundation

struct ClassData {
    static var classData: [[ClassData]] = Array(repeating: [], count: 6)
    
    var className: String
    var classRoom: String
    var nextTiming: Date?
    var judge: Bool = false
    
    init(className: String, classRoom: String) {
        self.className = className
        self.classRoom = classRoom
        self.nextTiming = nil
    }
    
    init() {
        self.className = "次は空きコマです。"
        self.classRoom = ""
        self.nextTiming = nil
        self.judge = false
    }
}

extension ClassData {
    static func setClassData(_ newClassData: ClassData, forDay day: Int, forPeriod period: Int) {
        if day < ClassData.classData.count {
            if period < ClassData.classData[day].count {
                ClassData.classData[day][period] = newClassData
            } else {
                ClassData.classData[day].append(newClassData)
            }
        }
    }
    
    static func printClassData() {
            for (dayIndex, day) in classData.enumerated() {
                for (periodIndex, periodClass) in day.enumerated() {
                    print("Day \(dayIndex), Period \(periodIndex): \(periodClass.className) in \(periodClass.classRoom)")
                }
            }
    }
    
    static func getNextClassInfo() -> ClassData {
        print("げっとねくすとくらすいんふぉはここから")
        let now = Date()
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: now) - 1 // 0: Sunday, 1: Monday, ...
        let minute = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        
        // Determine the current period based on the current time
        let period: Int
        switch minute {
        case ..<510:
            period = 0
        case ..<610:
            period = 1
        case ..<750:
            period = 2
        case ..<850:
            period = 3
        case ..<950:
            period = 4
        case ..<1050:
            period = 5
        case ..<1150:
            period = 6
        case ..<1250:
            period = 7
        default:
            period = 8
        }
        
        // Check if dayOfWeek is within the bounds of classData
        guard dayOfWeek < classData.count else {
            return ClassData() // return a default instance with "次は空きコマです。"
        }
        
        // Check if period is within the bounds of the sub-array for the specified day
        guard period < classData[dayOfWeek].count else {
            return ClassData() // return a default instance with "次は空きコマです。"
        }
        
        let nextClass = classData[dayOfWeek][period]
        
        // If the class name is empty, it means there's no class in that period
        if nextClass.className.isEmpty {
            return ClassData() // return a default instance with "次は空きコマです。"
        }
        
        print("Day of the week: \(dayOfWeek), Period: \(period)")
        print("Returning class data: \(nextClass.className), \(nextClass.classRoom)")
        
        return nextClass
    }
}*/
