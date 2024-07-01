//
//  MyClassDataStore+CoreDataProperties.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2024/06/27.
//
//

import Foundation
import CoreData


extension MyClassDataStore {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MyClassDataStore> {
        return NSFetchRequest<MyClassDataStore>(entityName: "MyClassDataStore")
    }

    @NSManaged public var dayAndPeriod: Int16
    @NSManaged public var classIdChangeable: Bool
    @NSManaged public var classRoom: String?
    @NSManaged public var classTitle: String?
    @NSManaged public var classURL: String?
    @NSManaged public var professorName: String?
    @NSManaged public var isNotifying: Bool
    @NSManaged public var classId: Int64

}

extension MyClassDataStore : Identifiable {

}
