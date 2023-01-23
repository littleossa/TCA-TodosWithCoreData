//
//  TodoClient.swift
//  TCA-TodosWithCoreData
//
//

import ComposableArchitecture

struct TodoClient {
    var all: () throws -> [Todo.State]
    var add: (_ todo: Todo.State) throws -> TodoAddResponse
    var remove: (_ todos: [Todo.State]) throws -> TodoRemoveResponse
    var edit: (_ todo: Todo.State) throws -> TodoEditResponse
    var rearrangeOrders: (_ todos: [Todo.State]) throws -> [Todo.State]
}

extension TodoClient: DependencyKey {
    
    // MARK: - Live
    static let liveValue = Self(
        all: {
            try CoreDataProvider.shared.getTodoStates()
        },
        add: { todo in
            try CoreDataProvider.shared.addTodo(todo)
        },
        remove: { todos in
            try CoreDataProvider.shared.removeTodo(todos)
        },
        edit: { todo in
            try CoreDataProvider.shared.editTodo(todo)
        },
        rearrangeOrders: { todos in
            try CoreDataProvider.shared.rearrangeOrdersOf(todos)
        }
    )
    
    // MARK: - Test
    static let testValue = Self(
        all: unimplemented("\(Self.self).all"),
        add: unimplemented("\(Self.self).add"),
        remove: unimplemented("\(Self.self).remove"),
        edit: unimplemented("\(Self.self).edit"),
        rearrangeOrders: unimplemented("\(Self.self).rearraneOrders")
    )
}

extension DependencyValues {
    var todoClient: TodoClient {
        get { self[TodoClient.self] }
        set { self[TodoClient.self] = newValue }
    }
}

// MARK: - Response
struct TodoAddResponse: Equatable {
    let addedTodo: Todo.State?
    let allTodos: [Todo.State]
}

struct TodoEditResponse: Equatable {
    let editedTodo: Todo.State?
    let allTodos: [Todo.State]
}

struct TodoRemoveResponse: Equatable {
    let removedTodos: [Todo.State]
    let allTodos: [Todo.State]
}
