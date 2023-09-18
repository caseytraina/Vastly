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
import AlgoliaSearchClient
import InstantSearch
import InstantSearchSwiftUI
import InstantSearchCore

// The user begins in this view. If there exists a user, then the user enters the video flow, otherwise they are onboarded.
struct ContentView: View {
    
    @EnvironmentObject private var authModel: AuthViewModel
//    @EnvironmentObject private var viewModel: VideoViewModel
//    static let algoliaController = AlgoliaController()

    var body: some View {
//        NavigationView {
//            SearchPage(searchBoxController: ContentView.algoliaController.searchBoxController,
//                       hitsController: ContentView.algoliaController.hitsController)
//        }.onAppear {
//            ContentView.algoliaController.searcher.search()
//        }
        
        
//        NewSearchBar()
        
        Group {
            if authModel.user != nil {
                HomeView(authModel: authModel)
                    .environmentObject(authModel)
            } else {
                GreetingView()
                    .environmentObject(authModel)
            }
        }
        
        
        
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
//}



