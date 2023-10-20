//
//  HomeView.swift
//  Vastly
//
//  Created by Casey Traina on 5/9/23.
//

import SwiftUI
import AVKit

enum Page: CaseIterable {
    
    case home
    case search
    case bookmarks
    case profile
    
    var title: String {
        switch self {
            
        case .home:
            return "Home"
        case .search:
            return "Search"
        case .bookmarks:
            return "Bookmarks"
        case .profile:
            return "Profile"
            
        }
    }
    
    var iconInactive: String {
        switch self {
            
        case .home:
            return "house"
        case .search:
            return "magnifyingglass"
        case .bookmarks:
            return "book.pages"
        case .profile:
            return "person"
        }
    }
    
    var iconActive: String {
        switch self {
            
        case .home:
            return "house.fill"
        case .search:
            return "magnifyingglass"
        case .bookmarks:
            return "book.pages.fill"
        case .profile:
            return "person.fill"
        }
    }
    
}

struct HomeView: View {
    @EnvironmentObject var viewModel: CatalogModel
    @EnvironmentObject var authModel: AuthViewModel

    @State var channel_index = 0
    
    @State var currentPage: Page = .home
    
    @State var isPlaying = true
    
//    init(authModel: AuthViewModel) {
//        _viewModel = StateObject(wrappedValue: VideoViewModel(authModel: authModel))
//    }
    
    var body: some View {
        
        // Create Background + Display Videos
        GeometryReader { geo in
            ZStack {
                //            LinearGradient(gradient: Gradient(colors: myGradient(channel_index: channel_index)), startPoint: .topLeading, endPoint: .bottom)
                //                .ignoresSafeArea()
                //                .transition(.opacity)
                //                .animation(.easeInOut(duration: 1.0), value: channel_index)
                
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                if viewModel.isProcessing || authModel.current_user == nil {
                    LoadingView()
                } else {
                    ForEach(0..<viewModel.channels.count) { index in
                        LinearGradient(gradient: Gradient(colors: myGradient(channel_index: index)), startPoint: .topLeading, endPoint: .bottom)
                            .ignoresSafeArea()
                            .opacity(channel_index == index ? 1 : 0)
                            .animation(.easeInOut(duration: 0.75), value: channel_index)
                    }
                    
                    VStack {
                        switch currentPage {
                            
                        case .home:
//                            NewVideoView(playing: $isPlaying, channel_index: $channel_index, viewModel: viewModel)
//                                .environmentObject(viewModel)
//                                .environmentObject(authModel)
                            CatalogVideoView(playing: $isPlaying,
                                             channel_index: $channel_index,
                                             viewModel: viewModel)
                                .environmentObject(viewModel)
                                .environmentObject(authModel)
                        case .search:
                            NewSearchBar(all_authors: viewModel.authors, oldPlaying: $isPlaying)
                                .environmentObject(authModel)
                                .environmentObject(viewModel)
                        case .bookmarks:
                            LikesListView(isPlaying: $isPlaying)
                                .environmentObject(authModel)
                                .environmentObject(viewModel)
                        case .profile:
                            ProfileView(isPlaying: $isPlaying)
                                .environmentObject(authModel)
                                .environmentObject(viewModel)
                        }
                        
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    
                    VStack {
                        Spacer()
                        NavBar(selected: $currentPage)
                            .frame(width: geo.size.width, height: geo.size.width / 5)
                        //                        .ignoresSafeArea()
                    }
                    .ignoresSafeArea()
                    //                .frame(width: screenSize.width, height: screenSize.height)
                }
            }
            
        }

        
        
    }
    // Creates Gradient
    private func myGradient(channel_index: Int) -> [Color] {
        
//        let background = Color(red: 18.0/255, green: 18.0/255, blue: 18.0/255)
//        let background = Color("BackgroundColor")
        let background = Color.black

        let channel_color = viewModel.channels[channel_index].color.opacity(0.8)

//        let purple = Color(red: 0.3803921568627451, green: 0.058823529411764705, blue: 0.4980392156862745)
        var gradient: [Color] = [channel_color]
        
        for _ in 0..<5 {
            gradient.append(background)
        }
        return gradient
    }

}

