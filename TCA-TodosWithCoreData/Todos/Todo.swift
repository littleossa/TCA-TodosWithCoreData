//
//  Todo.swift
//  TCA-TodosWithCoreData
//
//

import ComposableArchitecture
import SwiftUI

struct Todo: ReducerProtocol {
    
    struct State: Equatable, Identifiable {
        var text = ""
        var id: UUID
        var isComplete = false
        var order: Int
        
        init(with todoItem: TodoItem) {
            self.text = todoItem.text ?? ""
            self.id = todoItem.id ?? UUID()
            self.isComplete = todoItem.isComplete
            self.order = Int(todoItem.order)
        }
        
        init(text: String = "",
             id: UUID,
             isComplete: Bool = false,
             order: Int = 0) {
            self.text = text
            self.id = id
            self.isComplete = isComplete
            self.order = order
        }
    }
    
    enum Action: Equatable {
        case checkBoxToggled
        case textDidChanged(String)
        case todoEditResponse(TaskResult<TodoEditResponse>)
    }
    
    @Dependency(\.todoClient) var todoClient
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .checkBoxToggled:
            
            state.isComplete.toggle()
            let isComplete = state.isComplete
            
            let todo = Todo.State(text: state.text,
                                  id: state.id,
                                  isComplete: isComplete,
                                  order: state.order)
            
            return .task {
                await .todoEditResponse(
                    TaskResult {
                        try todoClient.edit(todo)
                    }
                )
            }
            
        case .textDidChanged(let text):
            let todo = Todo.State(text: text,
                                  id: state.id,
                                  isComplete: state.isComplete,
                                  order: state.order)
            return .task {
                await .todoEditResponse(
                    TaskResult {
                        try todoClient.edit(todo)
                    }
                )
            }
            
        case .todoEditResponse(.success(let response)):
            guard let todo = response.editedTodo else {
                return .none
            }
            state.text = todo.text
            return .none
            
        case .todoEditResponse(.failure):
            // TODO: - Error Handling
            return .none
        }
    }
}

struct TodoView: View {
    
    let store: StoreOf<Todo>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            HStack {
                Button {
                    viewStore.send(.checkBoxToggled)
                } label: {
                    Image(systemName: viewStore.isComplete ? "checkmark.square" : "square")
                }
                .buttonStyle(.plain)
                
                TextField("Untitled Todo",
                          text: viewStore.binding(get: \.text,
                                                  send: Todo.Action.textDidChanged))
            }
            .foregroundColor(viewStore.isComplete ? .gray : nil)
        }
    }
}

#if DEBUG
struct TodoView_Previews: PreviewProvider {
    static var previews: some View {
        TodoView(store: .init(initialState: .init(id: UUID(),
                                                  order: 0),
                              reducer: Todo.init()))
    }
}
#endif

