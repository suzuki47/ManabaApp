//
//  TaskDataManager.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2023/10/27.
//

import CoreData
import UIKit

class TaskDataManager {
    
    private let context: NSManagedObjectContext
    
    init() {
        self.context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    func toTaskDataStore(from task: taskData, context: NSManagedObjectContext) -> TaskDataStore {
        let taskDataStore = TaskDataStore(context: context)
        taskDataStore.name = task.name
        taskDataStore.dueDate = task.dueDate
        taskDataStore.detail = task.detail
        taskDataStore.taskType = Int16(task.taskType)
        taskDataStore.isNotified = task.isNotified
        // 他のプロパティも必要に応じて変換して設定します
        return taskDataStore
    }
    
    // TaskDataをTaskDataStoreに保存
    func saveTask(_ task: taskData) {
        let taskDataStore = self.toTaskDataStore(from: task, context: context)
        do {
            try context.save()
        } catch {
            print("タスクの保存に失敗しました: \(error)")
        }
    }
    
    // 指定したIDのTaskDataStoreを更新
    func updateTask(_ task: taskData) {
        let fetchRequest: NSFetchRequest<TaskDataStore> = TaskDataStore.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", task.id.uuidString)
        
        do {
            let fetchedTasks = try context.fetch(fetchRequest)
            if let existingTask = fetchedTasks.first {
                existingTask.name = task.name
                existingTask.dueDate = task.dueDate
                existingTask.detail = task.detail
                existingTask.taskType = Int16(task.taskType)
                // ... 他のプロパティも更新 ...
                try context.save()
            }
        } catch {
            print("タスクの更新に失敗しました: \(error)")
        }
    }
    
    // 指定したIDのTaskDataStoreを削除
    func deleteTask(by id: UUID) {
        let fetchRequest: NSFetchRequest<TaskDataStore> = TaskDataStore.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let fetchedTasks = try context.fetch(fetchRequest)
            if let taskToDelete = fetchedTasks.first {
                context.delete(taskToDelete)
                try context.save()
            }
        } catch {
            print("タスクの削除に失敗しました: \(error)")
        }
    }
    
    // TaskDataStoreをTaskDataに変換して全てのタスクを取得
    func fetchAllTasks() -> [taskData] {
        let fetchRequest: NSFetchRequest<TaskDataStore> = TaskDataStore.fetchRequest()
        do {
            let fetchedTasks = try context.fetch(fetchRequest)
            return fetchedTasks.map { taskData(from: $0) }
        } catch {
            print("タスクの取得に失敗しました: \(error)")
            return []
        }
    }
}
