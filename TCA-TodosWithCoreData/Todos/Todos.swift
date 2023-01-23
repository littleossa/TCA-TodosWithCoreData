//
//  Todos.swift
//  TCA-TodosWithCoreData
//
//

import ComposableArchitecture
import SwiftUI

enum Filter: LocalizedStringKey, CaseIterable, Hashable {
    case all = "All"
    case active = "Active"
    case completed = "Completed"
    
}

struct Todos: ReducerProtocol {
    
    struct State: Equatable {
        var editMode: EditMode = .inactive
        var filter: Filter = .all
        var todos: IdentifiedArrayOf<Todo.State> = []
        
        var filteredTodos: IdentifiedArrayOf<Todo.State> {
            switch filter {
            case .all:
                return todos.filter { !$0.isComplete}
            case .active:
                return todos
            case .completed:
                return todos.filter(\.isComplete)
            }
        }
    }
    
    enum Action: Equatable {
        case onAppear
        case addTodoButtonTapped
        case clearCompletedButtonTapped
        case onDelete(IndexSet)
        case editModeChanged(EditMode)
        case filterPicked(Filter)
        case move(IndexSet, Int)
        case sortCompletedTodos
        case todo(id: Todo.State.ID, action: Todo.Action)
        case getAllTodos(TaskResult<[Todo.State]>)
        case todoAddResponse(TaskResult<TodoAddResponse>)
        case todoRemoveResponse(TaskResult<TodoRemoveResponse>)
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.uuid) var uuid
    @Dependency(\.todoClient) var todoClient
    
    private enum TodoCompletionId {}
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
                
            case .onAppear:
                return .task {
                    await .getAllTodos(
                        TaskResult {
                            try todoClient.all()
                        }
                    )
                }
                
            case .addTodoButtonTapped:
                return .task {
                    await .todoAddResponse(
                        TaskResult {
                            try todoClient.add(Todo.State(id: uuid()))
                        }
                    )
                }
                
            case .clearCompletedButtonTapped:
                state.todos.removeAll(where: \.isComplete)
                return .none
                
            case .onDelete(let indexSet):
                let filteredTodos = state.filteredTodos
                var todos: [Todo.State] = []
                
                for index in indexSet {
                    todos.append(filteredTodos[index])
                }
                
                let removeTodos = todos
                
                return .task {
                    await .todoRemoveResponse(
                        TaskResult {
                            try todoClient.remove(removeTodos)
                        }
                    )
                }
                
            case .editModeChanged(let editMode):
                state.editMode = editMode
                return .none
                
            case .filterPicked(let filter):
                state.filter = filter
                return .none
                
            case .move(var source, var destination):
                if state.filter == .completed {
                    source = IndexSet(
                        source
                            .map { state.filteredTodos[$0] }
                            .compactMap { state.todos.index(id: $0.id) }
                    )
                    destination = (destination < state.filteredTodos.endIndex ? state.todos.index(id: state.filteredTodos[destination].id) : state.todos.endIndex) ?? destination
                }
                
                state.todos.move(fromOffsets: source,
                                 toOffset: destination)
                                
                return .task {
                    try await self.clock.sleep(for: .milliseconds(100))
                    return .sortCompletedTodos
                }
                
            case .sortCompletedTodos:
                state.todos.sort { $1.isComplete && !$0.isComplete }
                
                let todos = state.todos.elements

                return .task {
                    await .getAllTodos(
                        TaskResult {
                            try todoClient.rearrangeOrders(todos)
                        }
                    )
                }
                
            case .todo(id: _, action: .checkBoxToggled):
                return .run { send in
                    try await clock.sleep(for: .seconds(1))
                    await send(.sortCompletedTodos, animation: .default)
                }
                .cancellable(id: TodoCompletionId.self, cancelInFlight: true)
                
            case .todo:
                return .none
                
            case .getAllTodos(.success(let todos)):
                state.todos = IdentifiedArrayOf(uniqueElements: todos)
                return .none
                
            case .todoAddResponse(.success(let response)):
                
                guard let addedTodo = response.addedTodo else {
                    return .none
                }
                
                state.todos.insert(addedTodo, at: 0)
                
                let todos = state.todos.elements

                return .task {
                    await .getAllTodos(
                        TaskResult {
                            try todoClient.rearrangeOrders(todos)
                        }
                    )
                }
                
            case .todoRemoveResponse(.success(let response)):
                let removedIds = response.removedTodos.map { $0.id }
                removedIds.forEach { id in
                    state.todos.remove(id: id)
                }
                
                let todos = state.todos.elements

                return .task {
                    await .getAllTodos(
                        TaskResult {
                            try todoClient.rearrangeOrders(todos)
                        }
                    )
                }
                
            case .getAllTodos(.failure), .todoAddResponse(.failure), .todoRemoveResponse(.failure):
                // TODO: - Error Handling
                return .none
            }
        }
        .forEach(\.todos, action: /Action.todo(id:action:)) {
            Todo()
        }
    }
    
    private func updateOrder() {
        
    }
}
