//
//  valas_swiftuiApp.swift
//  valas-swiftui
//
//  Created by deni zakya on 27.12.25.
//

import SwiftUI

@main
struct valas_swiftuiApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
