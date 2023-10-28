//
//  NewVideoView.swift
//  Vastly
//
//  Created by Casey Traina on 8/10/23.
//

import SwiftUI
import AVFoundation

enum DragType {
    case unknown
    case vertical
    case horizontal
}

struct NewVideoView: View {
        
    @EnvironmentObject var viewModel: VideoViewModel
    @EnvironmentObject var authModel: AuthViewModel

    @Binding var activeChannel: Channel
    @Binding var playing: Bool

    @Binding var channel_index: Int
    @Binding var video_indices: [Int]
    @State var current_trending = 0
    
    @State var offset: CGSize = CGSize(width: 0, height: 0)
    
    @State var opacity = 1.0
    @State var dragOffset = 0.0
    
//    @State var isActive = false
    @State var startTime = Date()
    @State var endTime = Date()
    
    @State var previous_playing = 0
    @State var previous_channel: Channel = FOR_YOU_CHANNEL

    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false
    
    @State var isChannel = true
    @State var isDiscover = false
    
    @State var videoMode = true
    
    @State var authorButtonTapped = false
    
    @State var channelGuidePressed = false
    
    @State var dragType: DragType = .unknown

    @State var publisherIsTapped = false
    
    @State var isShareLinkActive = false
    @State private var openedVideo: Video?

    init(playing: Binding<Bool>, channel_index: Binding<Int>, activeChannel: Binding<Channel>, viewModel: VideoViewModel, video_indices: Binding<[Int]>) {
        self._playing = playing
        self._channel_index = channel_index
        self._activeChannel = activeChannel
        self._video_indices = video_indices
    }
    
    var body: some View {
        

        Group {
            ZStack {
                VStack {
                    Carousel(isPlaying: $playing, selected: $activeChannel, channel_index: $channel_index)
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
                                                VerticalVideoView(activeChannel: $activeChannel, current_playing: $video_indices[channel_index], isPlaying: $playing, dragOffset: $dragOffset, channel: channel, publisherIsTapped: $publisherIsTapped)
                                                    .environmentObject(viewModel)
                                                    .environmentObject(authModel)
                                                    .frame(width: screenSize.width, height: screenSize.height * 0.8)
                                                    .id(channel)
                                            }
                                            
                                        } else {
                                            Color("BackgroundColor")
                                                .frame(width: screenSize.width, height: screenSize.height * 0.8)
//                                                    .blur(radius: channel == activeChannel ? 0 : 3)
                                                .id(channel)
                                        }
                                        
                                    } //end for each
                                    
                                } // end HStack
                                .offset(x: offset.width)
                                
                            } //end scrollview
                            .scrollDisabled(true)
                            .onAppear {
                                print("APPEAR: \(video_indices[channel_index])")
                                viewModel.playerManager?.changeToChannel(to: activeChannel, shouldPlay: playing, newIndex: video_indices[channel_index])
                                proxy.scrollTo(activeChannel, anchor: .leading)
                            }
                            .onChange(of: activeChannel) { newChannel in
                                print("APPEAR ACTIVE")
                                if channel_index != viewModel.channels.firstIndex(where: {$0.id == newChannel.id}) ?? 0 {
                                    channel_index = viewModel.channels.firstIndex(where: {$0.id == newChannel.id}) ?? 0
                                }
                                                                                            
                                endTime = Date()
                                
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()

                                channelClicked(for: newChannel, with: authModel.user)
                                videoClicked(for: getVideo(i: video_indices[channel_index], in: activeChannel),
                                             with: authModel.user,
                                             profile: authModel.current_user,
                                             watchedIn: activeChannel)
                                
                                let duration = viewModel.playerManager?.getPlayer(for: getVideo(i: video_indices[channel_index], in: previous_channel)).items().last?.currentTime().seconds
                                
                                viewModel.playerManager?.changeToChannel(to: newChannel, shouldPlay: playing, newIndex: video_indices[channel_index])
                                
                                videoWatched(
                                    from: startTime,
                                    to: endTime,
                                    for: getVideo(i: video_indices[channel_index], in: previous_channel),
                                    time: (viewModel.playerManager?.getPlayer(for: getVideo(i: video_indices[channel_index], in: previous_channel)).currentItem!.duration.seconds) ?? 0.0,
                                    watched: duration,
                                    with: authModel.user,
                                    profile: authModel.current_user,
                                    viewModel: viewModel,
                                    watchedIn: previous_channel)
                                
                                startTime = Date()
                                updateMetadata()
                                
                                previous_channel = newChannel
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
                                        // Calculate new current index
                                        var changed = false
//                                            DispatchQueue.global(qos: .userInitiated).async {
                                            
                                            if abs(event.translation.width/screenSize.width) > abs(event.translation.height/screenSize.height) {
                                                // horizontal
                                                
                                                let vel = event.predictedEndTranslation.width
                                                let distance = event.translation.width
                                                
                                                if vel <= -screenSize.width/2 || distance <= -screenSize.width/2 {
                                                    if channel_index + 1 < viewModel.channels.count {
                                                        channel_index += 1
                                                        changed = true
                                                    }
                                                } else if vel >= screenSize.width/2 || distance >= screenSize.width/2 {
                                                    if channel_index > 0 {
                                                        channel_index -= 1
                                                        changed = true
                                                    }
                                                }
                                                
                                            } else {
                                                //vertical
                                                
                                                let vel = event.predictedEndTranslation.height
                                                let distance = event.translation.height
                                                
                                                if vel <= -screenSize.height/4 || distance <= -screenSize.height/2 {
                                                    if video_indices[channel_index] + 1 <= viewModel.videos[activeChannel]?.count ?? 1000 {
                                                        video_indices[channel_index] += 1
                                                        
                                                    }
                                                } else if vel >= screenSize.height/4 || distance >= screenSize.height/2 {
                                                    if video_indices[channel_index] > 0 {
                                                        video_indices[channel_index] -= 1
                                                        
                                                    }
                                                }
                                            }
                                            dragType = .unknown
        //                                    if !changed {
                                                offset = CGSize(width: 0, height: 0)
        //                                    }
                                            dragOffset = 0

//                                            }
                                    })
                            ) // end gesture
                            
                        }// end scroll view reader
                        
//                        if isShareLinkActive == true {
 
//                        }
                    } // end zstack
                    .frame(height: screenSize.height * 0.8)
                    .onOpenURL { incomingURL in
                        print("App was opened via URL: \(incomingURL)")
                        Task {
                            await handleIncomingURL(incomingURL)
                        }
                    }

                }
                
                .onChange(of: channel_index) { newIndex in
                    if activeChannel != viewModel.channels[newIndex] {
                        activeChannel = viewModel.channels[newIndex]
                    }
                    
                    addVideos(at: newIndex);
                                        
                    print(newIndex)
                    updateMetadata()
                }

                .onChange(of: video_indices[channel_index]) { newIndex in
                    endTime = Date()
                    
                    updateMetadata()
                    
                    if newIndex < viewModel.videos[activeChannel]?.count ?? 0 {
                        let previousVideo = getVideo(i: previous_playing, in: activeChannel)
                        let duration = viewModel.playerManager?.getPlayer(for: previousVideo).items().last?.currentTime().seconds

                        videoClicked(for: viewModel.videos[activeChannel]?[newIndex] ?? EMPTY_VIDEO,
                                     with: authModel.user,
                                     profile: authModel.current_user,
                                     watchedIn: activeChannel)
                        videoWatched(from: startTime,
                                     to: endTime,
                                     for: previousVideo,
                                     time: (viewModel.playerManager?.getPlayer(for: previousVideo).items().last!.duration.seconds) ?? 0.0,
                                     watched: duration,
                                     with: authModel.user,
                                     profile: authModel.current_user,
                                     viewModel: viewModel,
                                     watchedIn: activeChannel)
                        
                    }
                    
                    viewModel.playerManager?.changeToIndex(to: newIndex, shouldPlay: playing)
                    viewModel.playerManager?.playCurrentVideo()
                    
                    if abs(newIndex - (viewModel.videos[activeChannel]?.count)!) <= 2 {
                        Task {
                            await viewModel.addVideosTo(activeChannel)
                        }
                    }
                    
                    
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    
                    startTime = Date()
                    previous_playing = newIndex
                }
                .onAppear {
                    startTime = Date()
                    if let queue = viewModel.videos[activeChannel] {
                        if queue.count > video_indices[channel_index] {
                            
                            videoClicked(for: queue[video_indices[channel_index]] ?? EMPTY_VIDEO,
                                         with: authModel.user,
                                         profile: authModel.current_user,
                                         watchedIn: activeChannel)
                        }
                    }

                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.protectedDataDidBecomeAvailableNotification)) { _ in
                    DispatchQueue.main.async {
                        updateMetadata()
                        viewModel.playerManager?.isInBackground = false
                        
                    }
                    print("Available again")
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.protectedDataWillBecomeUnavailableNotification)) { _ in
                    DispatchQueue.main.async {
                        updateMetadata()
                        viewModel.playerManager?.isInBackground = true
                    }
                    print("From Away")
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    DispatchQueue.main.async {
                        updateMetadata()
                        viewModel.playerManager?.isInBackground = true
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
                    AuthorProfileView(author: getVideo(i: video_indices[channel_index], in: activeChannel).author, publisherIsTapped: $publisherIsTapped)
//                            .frame(width: screenSize.width, height: screenSize.height)
//                            .transition(.opacity)
//                            .animation(.easeOut, value: publisherIsTapped)
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
//                .ignoresSafeArea()
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
    
    private func addVideos(at index: Int) {
        
        
        // EARLY v Active Lazy Loading
        
//        let before  = index - 1
//        let after   = index + 1
//
//        if viewModel.channels.count > after {
//            let channel = viewModel.channels[after]
//            if video_indices[after] >= viewModel.videos[channel]?.count ?? 0 {
//                Task {
//                    await viewModel.getVideos(in: channel)
//                }
//            }
//        }
//
//        if before >= 0 {
//            let channel = viewModel.channels[before]
//            if video_indices[before] >= viewModel.videos[channel]?.count ?? 0 {
//                Task {
//                    await viewModel.getVideos(in: channel)
//                }
//            }
//
//        }
        
    }
    
}

//struct NewVideoView_Previews: PreviewProvider {
//    static var previews: some View {
//        NewVideoView()
//    }
//}
