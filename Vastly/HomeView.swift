//
//  HomeView.swift
//  Vastly
//
//  Created by Casey Traina on 5/9/23.
//

import SwiftUI
import AVKit
import MaterialDesignSymbol

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
            return "home"
        case .search:
            return "search"
        case .bookmarks:
            return "bookmark"
        case .profile:
            return "person"
        }
    }
    
    var iconActive: String {
        switch self {
            
        case .home:
            return "home-fill"
        case .search:
            return "search"
        case .bookmarks:
            return "bookmark-fill"
        case .profile:
            return "person-fill"
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var viewModel: CatalogViewModel
    @EnvironmentObject var authModel: AuthViewModel

    @Environment(\.scenePhase) private var scenePhase
    @State var currentPage: Page = .home
    @State var isPlaying = true
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                if viewModel.isProcessing || authModel.current_user == nil {
                    LoadingView()
                } else {
                    VStack {
                        switch currentPage {
                        case .home:
                            CatalogChannelView(playing: $isPlaying)
                                .environmentObject(viewModel)
                                .environmentObject(authModel)
                            
                        case .search:
                            SearchView(authors: viewModel.authors,
                                       playing: $isPlaying)
                                .environmentObject(authModel)
                                .environmentObject(viewModel)
                        case .bookmarks:
                            LikesListView(playing: $isPlaying)
                                .environmentObject(authModel)
                                .environmentObject(viewModel)
                        case .profile:
                            ProfileView(isPlaying: $isPlaying)
                                .environmentObject(authModel)
                                .environmentObject(viewModel)
                        }
                        
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .onChange(of: scenePhase) { newScenePhase in
                        switch newScenePhase {
                        case .active:
                            viewModel.playerManager?.updateBackgroundState(isInBackground: false)
                            print("SCENE: ACTIVE")
                        case .background:
                            viewModel.playerManager?.updateBackgroundState(isInBackground: true)
                            if viewModel.isVideoMode {
                                viewModel.pauseCurrentVideo()
                            }
                            print("SCENE: BACKGROUND")
                        default:
                            break
                        }
                    }
                    
                    VStack {
                        Spacer()
                        NavBar(selected: $currentPage)
                            .frame(width: geo.size.width, height: geo.size.width / 5)
                    }
                    .ignoresSafeArea()
                }
            }
        }
    }

    private func myGradient(_ channel: Channel) -> [Color] {
        let background = Color.black
        let channelColor = channel.color.opacity(0.8)
        var gradient: [Color] = [channelColor]
        for _ in 0..<5 {
            gradient.append(background)
        }
        return gradient
    }
}

