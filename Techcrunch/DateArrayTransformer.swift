//
//  DateArrayTransformer.swift
//  Techcrunch
//
//  Created by 鈴木悠太 on 2023/08/25.
//

import Foundation

class DateArrayTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let dates = value as? [Date] else { return nil }
        return try? NSKeyedArchiver.archivedData(withRootObject: dates, requiringSecureCoding: false)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? NSData else { return nil }
        return NSKeyedUnarchiver.unarchiveObject(with: data as Foundation.Data) as? [Date]
    }
}
extension DateArrayTransformer {
    static func notificationDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}
