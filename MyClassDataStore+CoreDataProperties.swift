//
//  MyClassDataStore+CoreDataProperties.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2024/02/27.
//
//

import Foundation
import CoreData


extension MyClassDataStore {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MyClassDataStore> {
        return NSFetchRequest<MyClassDataStore>(entityName: "MyClassDataStore")
    }

    @NSManaged public var classId: Int16
    @NSManaged public var classRoom: String?
    @NSManaged public var classTitle: String?
    @NSManaged public var classURL: String?
    @NSManaged public var professorName: String?
    @NSManaged public var classIdChangeable: Int16

}

extension MyClassDataStore : Identifiable {

}
