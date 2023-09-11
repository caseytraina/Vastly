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

    @State var activeChannel: Channel = Channel.allCases[0]
    
    @Binding var channel_index: Int
    @State var video_indices = [Int](repeating: 0, count: Channel.allCases.count)
    @State var current_trending = 0
    
    @State var offset: CGSize = CGSize(width: 0, height: 0)
    
    @State var playing = true
    
    @State var opacity = 1.0
    @State var dragOffset = 0.0
    
//    @State var isActive = false
    @State var startTime = Date()
    @State var endTime = Date()
    
    @State var previous_playing = 0
    @State var previous_channel: Channel = .foryou

    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false
    
    @State var isChannel = true
    @State var isDiscover = false
    
    @State var videoMode = true
    
    @State var authorButtonTapped = false
    
    @State var channelGuidePressed = false
    
    @State var dragType: DragType = .unknown

    @State var publisherIsTapped = false
    
    var body: some View {
        
        
        
        Group {
            if viewModel.isProcessing {
                LoadingView()
            } else {
                ZStack {
                    VStack {
                        Carousel(isPlaying: $playing, selected: $activeChannel)
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
                                        
                                        ForEach(Channel.allCases, id: \.self) { channel in
                                            if abs((Channel.allCases.firstIndex(of: activeChannel) ?? 0) - (Channel.allCases.firstIndex(of: channel) ?? 0)) <= 1 {
                                                
                                                
                                                //                                        if abs(channel_index - Channel.allCases.first(where: {$0 == channel})) <= 1 {
                                                VerticalVideoView(activeChannel: $activeChannel, current_playing: $video_indices[channel_index], isPlaying: $playing, dragOffset: $dragOffset, channelGuidePressed: $channelGuidePressed, channel: channel, publisherIsTapped: $publisherIsTapped)
                                                    .environmentObject(viewModel)
                                                    .environmentObject(authModel)
                                                    .frame(width: screenSize.width, height: screenSize.height * 0.8)
//                                                    .blur(radius: channel == activeChannel ? 0 : 3)
                                                    .id(channel)
                                                
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
                                    withAnimation(.easeOut(duration: 0.125)) {
                                        proxy.scrollTo(activeChannel, anchor: .leading)
                                    }
                                }
                                .frame(width: screenSize.width, height: screenSize.height * 0.8)
                                .onChange(of: activeChannel) { newChannel in
                                    withAnimation(.easeOut(duration: 0.125)) {
                                        proxy.scrollTo(newChannel, anchor: .leading)
                                    }
                                }
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
                                                        if channel_index + 1 < Channel.allCases.count {
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
                            
                            if channelGuidePressed {
                                ChannelSelectorView(activeChannel: $activeChannel, channel_index: $channel_index, video_indices: $video_indices, channelsExpanded: $channelGuidePressed)
                                    .environmentObject(viewModel)
                                    .frame(height: screenSize.height * 0.8)
                            }
                            
                        } // end zstack
                        .frame(height: screenSize.height * 0.8)

                    }
                    .onChange(of: channel_index) { newIndex in
                        if activeChannel != Channel.allCases[newIndex] {
                            activeChannel = Channel.allCases[newIndex]
                        }
                        updateMetadata()
                    }
                    .onChange(of: activeChannel) { newChannel in
                        if channel_index != Channel.allCases.firstIndex(where: {$0 == newChannel}) ?? 0 {
                            channel_index = Channel.allCases.firstIndex(where: {$0 == newChannel}) ?? 0
                        }
                        endTime = Date()
                        
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()

                        channelTapped(for: newChannel, with: authModel.user)
                        videoWatched(for: getVideo(i: video_indices[channel_index], in: activeChannel),
                                     with: authModel.user,
                                     profile: authModel.current_user)
                            
                        let previousVideo = getVideo(i: video_indices[channel_index], in: previous_channel)
                        let duration = viewModel.playerManager?.getPlayer(for: previousVideo).currentTime().seconds
                        
                        logWatchTime(from: startTime,
                                     to: endTime,
                                     for: previousVideo,
                                     time: (viewModel.playerManager?.getPlayer(for: previousVideo).currentItem!.duration.seconds) ?? 0.0,
                                     watched: duration,
                                     with: authModel.user,
                                     profile: authModel.current_user)
                        updateMetadata()
                        previous_channel = newChannel
                        startTime = Date()
                    }
                    .onChange(of: video_indices[channel_index]) { newIndex in
                        endTime = Date()

                        updateMetadata()
                        
                        let previousVideo = getVideo(i: previous_playing, in: activeChannel)
                        let duration = viewModel.playerManager?.getPlayer(for: previousVideo).currentTime().seconds
                        
                        videoWatched(for: viewModel.videos[activeChannel]?[newIndex] ?? EMPTY_VIDEO,
                                     with: authModel.user,
                                     profile: authModel.current_user)
                        logWatchTime(from: startTime,
                                     to: endTime,
                                     for: previousVideo,
                                     time: (viewModel.playerManager?.getPlayer(for: previousVideo).currentItem!.duration.seconds) ?? 0.0,
                                     watched: duration,
                                     with: authModel.user,
                                     profile: authModel.current_user)

                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        
                        previous_playing = newIndex
                        startTime = Date()
                    }
                    .onAppear {
                        startTime = Date()
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
                    
                    if publisherIsTapped {
                        AuthorProfileView(author: getVideo(i: video_indices[channel_index], in: activeChannel).author, publisherIsTapped: $publisherIsTapped)
//                            .frame(width: screenSize.width, height: screenSize.height)
//                            .transition(.opacity)
//                            .animation(.easeOut, value: publisherIsTapped)
                    }
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
