//
//  CatalogVideoView.swift
//  Vastly
//
//  Created by Michael Murray on 10/20/23
//

import SwiftUI
import AVFoundation

struct CatalogChannelView: View {
    
    enum DragType {
        case unknown
        case vertical
        case horizontal
    }
    
    @EnvironmentObject var viewModel: CatalogViewModel
    @EnvironmentObject var authModel: AuthViewModel
    
    @Binding var playing: Bool
        
    @State var offset: CGSize = CGSize(width: 0, height: 0)
    @State var opacity = 1.0
    @State var dragOffset = 0.0

    @State var startTime = Date()
    @State var endTime = Date()

    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false
    
    @State var isChannel = true
    @State var isDiscover = false
    
    @State var videoMode = true
    
    @State var authorButtonTapped = false
    @State var dragType: DragType = .unknown
    
    @State var publisherIsTapped = false
    
    @State var isShareLinkActive = false
    @State private var openedVideo: Video?
    
    var body: some View {
        Group {
            ZStack {
                VStack {
                    Carousel(isPlaying: $playing)
                        .environmentObject(viewModel)
                        .environmentObject(authModel)
                        .frame(height: screenSize.height*0.075)
                        .frame(width: screenSize.width)
                        .ignoresSafeArea()
                        .padding(.vertical)
                    Spacer()
                    ZStack {
                        ScrollViewReader { proxy in
                            ScrollView (.horizontal, showsIndicators: false) {
                                HStack {
                                    CatalogVideoView(channel: viewModel.currentChannel,
                                                     isPlaying: $playing,
                                                     dragOffset: $dragOffset,
                                                     publisherIsTapped: $publisherIsTapped)
                                    .environmentObject(viewModel)
                                    .environmentObject(authModel)
                                    .frame(width: screenSize.width, height: screenSize.height * 0.8)
                                    .id(viewModel.currentChannel)
                                }
                                .offset(x: offset.width)
                            }
                            .scrollDisabled(true)
                            .onChange(of: viewModel.catalog.activeChannel) { newChannel in
                                print("Channel changed in CatalogChannelView")
                                channelChanged(newChannel: newChannel)
                                withAnimation(.easeOut(duration: 0.125)) {
                                    proxy.scrollTo(newChannel, anchor: .leading)
                                }
                            }
                            .frame(width: screenSize.width, height: screenSize.height * 0.8)
                            .gesture(DragGesture()
                                .onChanged(onDragChanged)
                                .onEnded(onDragEnded)
                            )
                        }
                    }
                    .frame(height: screenSize.height * 0.8)
                    .onOpenURL { incomingURL in
                        print("App was opened via URL: \(incomingURL)")
                        Task {
                            await handleIncomingURL(incomingURL)
                        }
                    }
                }
                .onAppear {
                    startTime = Date()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.protectedDataDidBecomeAvailableNotification)) { _ in
                    DispatchQueue.main.async {
                        updateMetadata()
                    }
                    print("Available again")
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.protectedDataWillBecomeUnavailableNotification)) { _ in
                    DispatchQueue.main.async {
                        updateMetadata()
                    }
                    print("From Away")
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    DispatchQueue.main.async {
                        updateMetadata()
                    }
                    print("From Background")
                }
                .onChange(of: playing) { newPlaying in
                    if newPlaying {
                        viewModel.playCurrentVideo()
                    } else {
                        viewModel.pauseCurrentVideo()
                    }
                }
                
                if publisherIsTapped {
                    if let video = viewModel.catalog.currentVideo {
                        AuthorProfileView(author: video.author,
                                          publisherIsTapped: $publisherIsTapped)
                    }
                }
                if let openedVideo {
                    NavigationLink("", destination: SingleVideoView(isActive: $isShareLinkActive, video: openedVideo))
                        .environmentObject(viewModel)
                        .environmentObject(authModel)
                    .hidden()
                }
            }
        }
        .overlay(
            Group {
                if !hasSeenTutorial && !viewModel.isProcessing {
                    withAnimation {
                        TutorialView(showTutorial: $hasSeenTutorial)
                    }
                }
            }
        )
        
    }

    private func onDragChanged(_ event: DragGesture.Value) {
        if dragType == .unknown {
            if abs(event.translation.width/screenSize.width) > abs(event.translation.height/screenSize.height)*5 {
                dragType = .horizontal
                offset = CGSize(width: event.translation.width, height: 0)
            } else {
                dragType = .vertical
                dragOffset = event.translation.height
            }
        } else if dragType == .horizontal {
            offset = CGSize(width: event.translation.width, height: 0)
        } else if dragType == .vertical {
            dragOffset = event.translation.height
        }
    }
        
    private func onDragEnded(_ event: DragGesture.Value) {
        
        if abs(event.translation.width/screenSize.width) > abs(event.translation.height/screenSize.height) {
            // horizontal
            
            let vel = event.predictedEndTranslation.width
            let distance = event.translation.width
            
            if vel <= -screenSize.width/2 || distance <= -screenSize.width/2 {
                viewModel.changeToNextChannel(shouldPlay: playing)
            } else if vel >= screenSize.width/2 || distance >= screenSize.width/2 {
                viewModel.changeToPreviousChannel(shouldPlay: playing)
            }
            
        } else {
            //vertical
            
            let vel = event.predictedEndTranslation.height
            let distance = event.translation.height
            
            if vel <= -screenSize.height/4 || distance <= -screenSize.height/2 {
                viewModel.changeToNextVideo()
                
                
            } else if vel >= screenSize.height/4 || distance >= screenSize.height/2 {
                viewModel.changeToPreviousVideo()
            }
        }
        dragType = .unknown
        offset = CGSize(width: 0, height: 0)
        dragOffset = 0
        
    }
    
    private func channelChanged(newChannel: Channel) {
        endTime = Date()
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        let catalog = viewModel.catalog
        if let currentVideo = catalog.currentVideo {
            channelClicked(for: newChannel, with: authModel.user)
            videoClicked(for: currentVideo,
                         with: authModel.user,
                         profile: authModel.current_user,
                         watchedIn: catalog.activeChannel)
            
            if let previousVideo = catalog.peekPreviousVideo() {
                let duration = viewModel.playerManager?.getPlayer(for: previousVideo).currentTime().seconds
                // This must be a value since we changed to a new channel
                let previousChannel = catalog.peekPreviousChannelInHistory()!
                videoWatched(
                    from: startTime,
                    to: endTime,
                    for: previousVideo,
                    time: duration ?? 0.0,
                    watched: duration,
                    with: authModel.user,
                    profile: authModel.current_user,
                    viewModel: viewModel,
                    watchedIn: previousChannel.channel)
            }
            startTime = Date()
            updateMetadata()
        }
    }
    
    private func updateMetadata() {
        if let video = viewModel.catalog.currentVideo {
            viewModel.playerManager?.updateNowPlayingInfo(for: video)
        }
    }
    
    private func handleIncomingURL(_ url: URL) async {
        
        print("Handling URL.")
        
        guard url.scheme == "vastlyapp" else {
            print("Invalid Scheme")
            return
        }
        print("Scheme Successful.")
        
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("Invalid URL")
            return
        }
        print("Scheme Successful.")
        
        
        guard let action = components.host, action == "open-video" else {
            print("Unknown URL, we can't handle this one!")
            return
        }
        
        guard let idQueryItem = components.queryItems?.first(where: { $0.name == "id" }), let videoId = idQueryItem.value else {
            print("id query item not found in URL")
            return
        }
        
        if let video = self.viewModel.catalog.getVideo(id: videoId) {
            print("Finished querying video.")
            playing = false
            openedVideo = video
            isShareLinkActive = true
        } else {
            print("There was an issue querying the selected video.")
        }
        
        
    }
}
