//
//  ClassData.swift
//  Techcrunch
//
//  Created by 鈴木悠太 on 2023/08/16.
//

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
