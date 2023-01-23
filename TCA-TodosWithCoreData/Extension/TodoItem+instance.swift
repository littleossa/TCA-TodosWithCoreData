//
//  TodoItem+instance.swift
//  TCA-TodosWithCoreData
//
//

import CoreData

extension TodoItem {
    static func instance(from todo: Todo.State, with context: NSManagedObjectContext) -> TodoItem {
        let newTodoItem = TodoItem(context: context)
        newTodoItem.id = todo.id
        newTodoItem.text = todo.text
        newTodoItem.isComplete = todo.isComplete
        newTodoItem.order = Int32(todo.order)
        
        return newTodoItem
    }
}
