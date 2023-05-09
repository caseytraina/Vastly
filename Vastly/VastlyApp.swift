//
//  VastlyApp.swift
//  Vastly
//
//  Created by Casey Traina on 5/9/23.
//

import SwiftUI

@main
struct VastlyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
