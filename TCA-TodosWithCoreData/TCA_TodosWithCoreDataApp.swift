//
//  TCA_TodosWithCoreDataApp.swift
//  TCA-TodosWithCoreData
//
//

import SwiftUI
import ComposableArchitecture

@main
struct TCA_TodosWithCoreDataApp: App {

    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: Todos.State(),
                                 reducer: Todos()._printChanges()))
        }
    }
}
