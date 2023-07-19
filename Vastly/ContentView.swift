//
//  ContentView.swift
//  Vastly
//
//  Created by Casey Traina on 5/9/23.
//

import SwiftUI
import CoreData
import FirebaseCore
import FirebaseAuth

struct ContentView: View {
    
    @EnvironmentObject private var authModel: AuthViewModel
//    @EnvironmentObject private var viewModel: VideoViewModel
    
    var body: some View {
        
        Group {
            if authModel.user != nil {
                HomeView()
//                    .environmentObject(viewModel)
                    .environmentObject(authModel)
//                    .environmentObject(authModel)
            } else {
                GreetingView()
                    .environmentObject(authModel)
//                    .environmentObject(authModel)
//                    .environmentObject(viewModel)

            }
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
//}



