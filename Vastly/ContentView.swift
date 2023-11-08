//
//  ContentView.swift
//  Vastly
//
//  Created by Casey Traina on 5/9/23.
//

import SwiftUI
//import CoreData
//import FirebaseCore
//import FirebaseAuth
//import AlgoliaSearchClient
//import InstantSearch
//import InstantSearchSwiftUI
//import InstantSearchCore

// The user begins in this view. If there exists a user, then the user enters the video flow, otherwise they are onboarded.
struct ContentView: View {
    @EnvironmentObject private var authModel: AuthViewModel
    @EnvironmentObject private var viewModel: VideoViewModel
    var body: some View {
        Group {
            if authModel.user != nil {
                HomeView()
                    .environmentObject(authModel)
                    .environmentObject(viewModel)
            } else {
                GreetingView()
                    .environmentObject(authModel)
            }
        }
    }
}
