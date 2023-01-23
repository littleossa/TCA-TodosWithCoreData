//
//  Persistence.swift
//  TCA-TodosWithCoreData
//
//

import CoreData

class CoreData {
    static var shared = CoreData()
    
    private let containerName = "TodoItem"
    private let todoItemEntityName = "TodoItem"
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: containerName)
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                print(error)
            }
        })
        return container
    }()
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print(error)
            }
        }
    }
}

extension CoreData {
        
    func fetchRequest() -> NSFetchRequest<TodoItem> {
        let request = NSFetchRequest<TodoItem>(entityName: todoItemEntityName)
        request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        return request
    }
}
