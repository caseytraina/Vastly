//
//  ContentView.swift
//  Vastly
//
//  Created by Casey Traina on 5/9/23.
//

import SwiftUI

// The user begins in this view. If there exists a user, then the user enters the video flow, otherwise they are onboarded.
struct ContentView: View {
    @EnvironmentObject private var authModel: AuthViewModel
    @EnvironmentObject private var viewModel: CatalogViewModel
    @EnvironmentObject private var videoViewModel: VideoViewModel
    
    var body: some View {
        Group {
            if authModel.user != nil {
                HomeView()
                    .environmentObject(authModel)
                    .environmentObject(viewModel)
                    .environmentObject(videoViewModel)
            } else {
                GreetingView()
                    .environmentObject(authModel)
            }
        }
    }
}
