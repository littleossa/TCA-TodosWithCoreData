//
//  CoreDataProvider.swift
//  TCA-TodosWithCoreData
//
//

import ComposableArchitecture
import CoreData

class CoreDataProvider {
    
    static var shared = CoreDataProvider()
    private let context = CoreData.shared.context
    
    func getTodoStates() throws -> [Todo.State] {
        let todoStates = try getTodoItems().map { Todo.State(with: $0) }
        return todoStates
    }
    
    func addTodo(_ todo: Todo.State) throws -> TodoAddResponse {
        
        let hasTodo = try hasTodo(todo)
        
        guard !hasTodo else {
            return TodoAddResponse(addedTodo: nil,
                                   allTodos: try getTodoStates())
        }
        
        let todoItem = TodoItem.instance(from: todo, with: context)
        
        try context.save()
        
        return TodoAddResponse(addedTodo: Todo.State(with: todoItem),
                               allTodos: try getTodoStates())
    }
    
    func removeTodo(_ todos: [Todo.State]) throws -> TodoRemoveResponse {
        
        var removedTodos: [Todo.State] = []
        
        try todos.forEach { todo in
            let todoItems = try getTodoItems()
            if let itemId = todoItems.filter({ $0.id == todo.id }).first?.objectID,
               let todoItem = context.object(with: itemId) as? TodoItem {
                context.delete(todoItem)
                removedTodos.append(todo)
            }
        }
        try context.save()
        
        return TodoRemoveResponse(removedTodos: removedTodos,
                                  allTodos: try getTodoStates())
    }
    
    func editTodo(_ todo: Todo.State) throws -> TodoEditResponse {
        
        let todoItems = try getTodoItems()
        guard let itemId = todoItems.filter({ $0.id == todo.id }).first?.objectID,
              let todoItem = context.object(with: itemId) as? TodoItem
        else {
            return TodoEditResponse(editedTodo: nil,
                                    allTodos: try getTodoStates())
        }
        
        todoItem.text = todo.text
        todoItem.isComplete = todo.isComplete
        try context.save()
        
        return TodoEditResponse(editedTodo: Todo.State(with: todoItem),
                                allTodos: try getTodoStates())
    }
    
    func rearrangeOrdersOf(_ todos: [Todo.State]) throws -> [Todo.State] {
        
        var order: Int32 = 0
        
        try todos.forEach { todo in
            let todoItems = try getTodoItems()
            if let itemId = todoItems.filter({ $0.id == todo.id }).first?.objectID,
               let todoItem = context.object(with: itemId) as? TodoItem {
                
                todoItem.order = order
                order += 1
            }
        }
        try context.save()
        
        return try getTodoStates()
    }
    
    // MARK: - Private
    
    private func getTodoItems() throws -> [TodoItem] {
        var todoItems = [TodoItem]()
        todoItems = try context.fetch(CoreData.shared.fetchRequest())
        
        return todoItems
    }
    
    private func hasTodo(_ todo: Todo.State) throws -> Bool {
        let todo = try getTodoItems().filter { $0.id == todo.id }.first
        return todo != nil
    }
}
