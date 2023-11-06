//
//  CatalogVideoView.swift
//  Vastly
//
//  Created by Michael Murray on 10/20/23
//

import SwiftUI
import AVFoundation

struct CatalogVideoView: View {
    enum DragType {
        case unknown
        case vertical
        case horizontal
    }
    
    @EnvironmentObject var viewModel: CatalogViewModel
    @EnvironmentObject var authModel: AuthViewModel
    
    @State var activeChannel: Channel
    @Binding var playing: Bool
    
    @Binding var channelIndex: Int
    @Binding var videoIndex: Int
    //    @State var video_indices: [Int]
    //    @State var current_trending = 0
    
    @State var offset: CGSize = CGSize(width: 0, height: 0)
    @State var opacity = 1.0
    @State var dragOffset = 0.0
    
    //    @State var isActive = false
    @State var startTime = Date()
    @State var endTime = Date()
    
    //    @State var previous_playing = 0
    //    @State var previous_channel: Channel = FOR_YOU_CHANNEL
    
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false
    
    @State var isChannel = true
    @State var isDiscover = false
    
    @State var videoMode = true
    
    @State var authorButtonTapped = false
    @State var dragType: DragType = .unknown
    
    @State var publisherIsTapped = false
    
    @State var isShareLinkActive = false
    @State private var openedVideo: Video?
    
    init(playing: Binding<Bool>,
         channelIndex: Binding<Int>,
         viewModel: CatalogViewModel) {
        self._playing = playing
        self._channelIndex = channelIndex
        //        self._video_indices = State(initialValue: [Int](repeating: 0, count: viewModel.channels.count))
    }
    
    func activeVideo() -> Video? {
        return self.activeChannel.currentVideo()
    }
    
    var body: some View {
        Group {
            ZStack {
                VStack {
                    Carousel(isPlaying: $playing,
                             selected: $activeChannel,
                             channel_index: $channelIndex)
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
                                    ForEach(viewModel.channels, id: \.self) { channel in
                                        if abs((viewModel.channels.firstIndex(of: activeChannel) ?? 0) - (viewModel.channels.firstIndex(of: channel) ?? 0)) <= 1 {
                                            
                                            if (viewModel.videos[channel] ?? []).isEmpty {
                                                ZStack {
                                                    Color("BackgroundColor")
                                                    MyText(text: "It seems you've seen all these videos. Try a new channel!", size: screenSize.width * 0.05, bold: true, alignment: .center, color: .white)
                                                }
                                                .frame(width: screenSize.width, height: screenSize.height * 0.8)
                                            } else {
                                                CatalogVerticalVideoView(activeChannel: $activeChannel,
                                                                         activeVideo: activeVideo(),
                                                                         isPlaying: $playing,
                                                                         dragOffset: $dragOffset,
                                                                         channel: channel,
                                                                         publisherIsTapped: $publisherIsTapped)
                                                .environmentObject(viewModel)
                                                .environmentObject(authModel)
                                                .frame(width: screenSize.width, height: screenSize.height * 0.8)
                                                .id(channel)
                                            }
                                            
                                        } else {
                                            Color("BackgroundColor")
                                                .frame(width: screenSize.width, height: screenSize.height * 0.8)
                                                .id(channel)
                                        }
                                    }
                                }
                                .offset(x: offset.width)
                            }
                            .scrollDisabled(true)
                            .onAppear {
                                viewModel.playerManager?.changeToChannel(to: activeChannel,
                                                                         shouldPlay: playing)
                                withAnimation(.easeOut(duration: 0.125)) {
                                    proxy.scrollTo(activeChannel, anchor: .leading)
                                }
                            }
                            .onChange(of: activeChannel) { newChannel in
                                if channelIndex != viewModel.channels.firstIndex(where: {$0.id == newChannel.id}) ?? 0 {
                                    channelIndex = viewModel.channels.firstIndex(where: {$0.id == newChannel.id}) ?? 0
                                }
                                
                                endTime = Date()
                                
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                
                                viewModel.playerManager?.changeToChannel(to: newChannel, shouldPlay: playing)
                                
                                let currentVideo = viewModel.catalog.currentVideo()
                                let previousVideo = viewModel.catalog.peekPreviousVideo()
                                let previousChannel = viewModel.catalog.peekPreviousChannel()
                                
                                // TODO: move this into the catalog
                                channelClicked(for: newChannel, with: authModel.user)
                                videoClicked(for: currentVideo,
                                             with: authModel.user,
                                             profile: authModel.current_user,
                                             watchedIn: activeChannel)
                                
                                let duration = viewModel.playerManager?.getPlayer(for: previousVideo).currentTime().seconds
                                
                                videoWatched(
                                    from: startTime,
                                    to: endTime,
                                    for: previousVideo,
                                    time: duration ?? 0.0,
                                    watched: duration,
                                    with: authModel.user,
                                    profile: authModel.current_user,
                                    viewModel: viewModel,
                                    watchedIn: previousChannel?.channel)
                                startTime = Date()
                                updateMetadata()
                                withAnimation(.easeOut(duration: 0.125)) {
                                    proxy.scrollTo(newChannel, anchor: .leading)
                                }
                                
                            }
                            .frame(width: screenSize.width, height: screenSize.height * 0.8)
                            .gesture(DragGesture()
                                .onChanged({ event in
                                    if dragType == .unknown {
                                        if abs(event.translation.width/screenSize.width) > abs(event.translation.height/screenSize.height)*5 {
                                            dragType = .horizontal
                                            offset = CGSize(width: event.translation.width, height: 0)
                                        } else {
                                            dragType = .vertical
                                            dragOffset = event.translation.height
                                            //                                    offset = CGSize(width: 0, height: event.translation.height)
                                        }
                                    } else if dragType == .horizontal {
                                        offset = CGSize(width: event.translation.width, height: 0)
                                    } else if dragType == .vertical {
                                        dragOffset = event.translation.height
                                        //                                offset = CGSize(width: 0, height: event.translation.height)
                                    }
                                })
                                    .onEnded({ event in
                                        if abs(event.translation.width/screenSize.width) > abs(event.translation.height/screenSize.height) {
                                            // horizontal
                                            
                                            let vel = event.predictedEndTranslation.width
                                            let distance = event.translation.width
                                            
                                            if vel <= -screenSize.width/2 || distance <= -screenSize.width/2 {
                                                if viewModel.catalog.nextChannel() {
                                                    // TODO: Remove this internal channel index
                                                    channelIndex += 1
                                                }
                                            } else if vel >= screenSize.width/2 || distance >= screenSize.width/2 {
                                                if viewModel.catalog.previousChannel() {
                                                    channelIndex -= 1
                                                }
                                            }
                                            
                                        } else {
                                            //vertical
                                            
                                            let vel = event.predictedEndTranslation.height
                                            let distance = event.translation.height
                                            
                                            if vel <= -screenSize.height/4 || distance <= -screenSize.height/2 {
                                                viewModel.catalog.nextVideo()
                                                //                                                    if video_indices[channel_index] + 1 <= viewModel.videos[activeChannel]?.count ?? 1000 {
                                                //                                                        video_indices[channel_index] += 1
                                                //
                                                //                                                    }
                                            } else if vel >= screenSize.height/4 || distance >= screenSize.height/2 {
                                                viewModel.catalog.previousVideo()
                                                //                                                    if video_indices[channel_index] > 0 {
                                                //                                                        video_indices[channel_index] -= 1
                                                //
                                                //                                                    }
                                            }
                                        }
                                        dragType = .unknown
                                        offset = CGSize(width: 0, height: 0)
                                        dragOffset = 0
                                    })
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
                
                .onChange(of: channelIndex) { newIndex in
                    if activeChannel != viewModel.channels[newIndex] {
                        activeChannel = viewModel.channels[newIndex]
                    }
                    updateMetadata()
                }
                
                .onChange(of: viewModel.catalog.currentVideo) { newVideo in
                    endTime = Date()
                    updateMetadata()
                    
//                    viewModel.playerManager?.changeToIndex(to: newIndex, shouldPlay: playing)
                    let previousVideo = viewModel.catalog.peekPreviousVideo()
                    let duration = viewModel.playerManager?.getPlayer(for: previousVideo).currentTime().seconds
                    videoClicked(for: viewModel.catalog.currentVideo ?? EMPTY_VIDEO,
                                 with: authModel.user,
                                 profile: authModel.current_user,
                                 watchedIn: activeChannel)
                    videoWatched(from: startTime,
                                 to: endTime,
                                 for: previousVideo,
                                 time: duration ?? 0.0,
                                 watched: duration,
                                 with: authModel.user,
                                 profile: authModel.current_user,
                                 viewModel: viewModel,
                                 watchedIn: activeChannel)
                    
                    
                    viewModel.playerManager?.playCurrentVideo()
                    
                    
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    
                    startTime = Date()
//                    previous_playing = newIndex
                }
                .onAppear {
                    startTime = Date()
//                    if let queue = viewModel.videos[activeChannel] {
//                        if queue.count > video_indices[channel_index] {
                            
//                            videoClicked(for: queue[video_indices[channel_index]] ?? EMPTY_VIDEO,
//                                         with: authModel.user,
//                                         profile: authModel.current_user,
//                                         watchedIn: activeChannel)
//                        }
//                    }
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
                        viewModel.playerManager?.playCurrentVideo()
                    } else {
                        viewModel.playerManager?.pauseCurrentVideo()
                    }
                }
                
                if publisherIsTapped {
                    AuthorProfileView(author: viewModel.catalog.currentVideo.author,
                                      publisherIsTapped: $publisherIsTapped)
                }
                if let openedVideo {
                    NavigationLink("", destination: SingleVideoView(video: openedVideo)
                        .environmentObject(viewModel)
                        .environmentObject(authModel), isActive: $isShareLinkActive)
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
    
    private func updateMetadata() {
        if let video = viewModel.playerManager?.getCurrentVideo() {
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
        
        if let video = await viewModel.getVideo(id: videoId) {
            print("Finished querying video.")
            playing = false
            openedVideo = video
            isShareLinkActive = true
        } else {
            print("There was an issue querying the selected video.")
        }
        
        
    }
    
    private func getVideo(i: Int, in channel: Channel) -> Video {
        
        var video = EMPTY_VIDEO
        
        if let vids = viewModel.videos[channel] {
            if i < vids.count && !vids.isEmpty {
                video = vids[i]
            }
        }
        return video
    }
}

//struct NewVideoView_Previews: PreviewProvider {
//    static var previews: some View {
//        NewVideoView()
//    }
//}