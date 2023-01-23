//
//  AppView.swift
//  TCA-TodosWithCoreData
//
//  Created by 平岡修 on 2023/01/23.
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    let store: StoreOf<Todos>
    @ObservedObject var viewStore: ViewStore<ViewState, Todos.Action>
    
    init(store: StoreOf<Todos>) {
        self.store = store
        self.viewStore = ViewStore(store.scope(state: ViewState.init(state:)))
    }
    
    struct ViewState: Equatable {
        let editMode: EditMode
        let filter: Filter
        let isClearCompletedButtonDisabled: Bool
        
        init(state: Todos.State) {
            self.editMode = state.editMode
            self.filter = state.filter
            self.isClearCompletedButtonDisabled = !state.todos.contains(where: \.isComplete)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Picker("Filter",
                       selection: viewStore.binding(get: \.filter,
                                                    send: Todos.Action.filterPicked)
                        .animation()) {
                    ForEach(Filter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                List {
                    ForEachStore(store.scope(state: \.filteredTodos,
                                             action: Todos.Action.todo(id:action:))) {
                        TodoView(store: $0)
                    }
                    .onDelete { self.viewStore.send(.onDelete($0)) }
                    .onMove { self.viewStore.send(.move($0, $1)) }
                }
            }
            .navigationTitle("Todos")
            .navigationBarItems(trailing: HStack(spacing: 20) {
                EditButton()
                
                Button("Clear Completed") {
                    self.viewStore.send(.clearCompletedButtonTapped, animation: .default)
                }
                .disabled(self.viewStore.isClearCompletedButtonDisabled)
                
                Button("Add Todo") { self.viewStore.send(.addTodoButtonTapped, animation: .default) }
            })
            .onAppear {
                self.viewStore.send(.onAppear)
            }
            .environment(\.editMode,
                          self.viewStore.binding(get: \.editMode,
                                                 send: Todos.Action.editModeChanged))
        }
        .navigationViewStyle(.stack)
    }
}

extension IdentifiedArray where ID == Todo.State.ID, Element == Todo.State {
    static let mock: Self = [
        Todo.State(text: "Check Mail",
                   id: UUID(uuidString: "DEADBEEF-DEAD-BEEF-DEAD-BEEDDEADBEEF")!,
                   isComplete: false,
                   order: 0),
        Todo.State(text: "Buy Milk",
                   id: UUID(uuidString: "CAFEBEEF-CAFE-BEEF-CAFE-BEEFCAFEBEEF")!,
                   isComplete: false,
                   order: 1),
        Todo.State(text: "Call Mom",
                   id: UUID(uuidString: "D00DCAFE-D00D-CAFE-D00D-CAFED00DCAFE")!,
                   isComplete: true,
                   order: 2),
    ]
}


#if DEBUG
struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(store: Store(initialState: Todos.State(todos: .mock),
                             reducer: Todos()))
    }
}
#endif
