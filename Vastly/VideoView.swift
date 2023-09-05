//
//  VideoView.swift
//  Vastly
//
//  Created by Casey Traina on 5/11/23.
//

let SCROLLVIEW_SIZE = screenSize.height * 0.55

import Foundation
import SwiftUI

// Simple view to determine if videos have been loaded in yet or not

//struct VideoView: View {
//    @EnvironmentObject var viewModel: VideoViewModel
//    @EnvironmentObject var authModel: AuthViewModel
//
//    @State var activeChannel: Channel = Channel.allCases[0]
//    
//    @Binding var channel_index: Int
//    @State var video_indices = [Int](repeating: 0, count: Channel.allCases.count)
//    @State var current_trending = 0
//    
//    @State var offset: CGSize = CGSize(width: 0, height: 0)
//    
//    @State var playing = true
//    
//    @State var opacity = 1.0
//    @State var dragOffset = 0.0
////    @State var isActive = false
//    
//    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = true
//    
//    @State var isChannel = true
//    @State var isDiscover = false
//    
//    @State var videoMode = true
//    
//    @State var authorButtonTapped = false
//    
//    @State var channelsExpanded = false
//    
//    var body: some View {
//        Group {
//            if viewModel.isProcessing {
//                LoadingView()
//            } else {
//                ScrollViewReader { proxy in
//                    VStack {
////                        TopTextView(activeChannel: $activeChannel, video_index: $video_indices[channel_index], videos: viewModel.videos, isChannel: $isChannel, isDiscover: $isDiscover, videoIsOn: $videoMode, isPlaying: $playing)
////                            .frame(maxHeight: screenSize.height*0.125)
////                            .environmentObject(viewModel)
////                            .environmentObject(authModel)
//                        Carousel(isPlaying: $playing, selected: $activeChannel)
//                            .environmentObject(viewModel)
//                            .environmentObject(authModel)
//                            .frame(maxHeight: screenSize.height*0.125)
//                            .padding()
//
//                        if !channelsExpanded {
//                            Spacer()
//                        }
//                        if isDiscover {
//                            Spacer()
////                            TrendingView(videoMode: $videoMode, current_index: $current_trending, isDiscover: $isDiscover)
////                                .environmentObject(viewModel)
////                                .environmentObject(authModel)
////                                .frame(height: screenSize.height * 0.8)
//                        } else {
//
////                            VerticalVideoView(activeChannel: $activeChannel, current_playing: $video_indices[channel_index], isPlaying: $playing)
////                                .environmentObject(viewModel)
////                                .environmentObject(authModel)
////                                .frame(minHeight: screenSize.height * 0.8)
////                            .frame(maxHeight: .infinity)
//                            TrendingView(videoMode: $videoMode, current_index: $current_trending, isDiscover: $isDiscover)
//                                .environmentObject(viewModel)
//                                .environmentObject(authModel)
//                            .offset(offset)
//                            .onChange(of: isChannel) { newValue in
//                                proxy.scrollTo(channel_index)
//                            }
//                            .onChange(of: isDiscover) { newValue in
//                                if newValue {
//                                    playing = false
//                                    viewModel.playerManager?.pauseCurrentVideo()
//                                }
//                            }
//                            .onAppear {
//                                //                            DispatchQueue.global(qos: .userInitiated).async {
//                                withAnimation {
//                                    proxy.scrollTo(channel_index, anchor: .center)
//                                }
//                                //                            }
//                                Task.init {
//                                    if authModel.isLoggedIn {
//                                        await authModel.configureUser(authModel.current_user?.phoneNumber ?? authModel.current_user?.email ?? "")
//                                    }
//                                }
//                                DispatchQueue.main.async {
//                                    updateMetadata()
//                                }
//                                print("From Appear")
//                            }
//                            .onChange(of: channel_index) { newChannel in
//                                //                            DispatchQueue.global(qos: .userInitiated).async {
//                                withAnimation {
//                                    proxy.scrollTo(channel_index, anchor: .center)
//                                }
//                                //                            }
//                                updateMetadata()
//                                print("From channel")
//                            }
//                            .onChange(of: video_indices[channel_index]) { newIndex in
//                                updateMetadata()
//                                print("From video_index")
//                            }
//                            .onReceive(NotificationCenter.default.publisher(for: UIApplication.protectedDataWillBecomeUnavailableNotification)) { _ in
//                                DispatchQueue.main.async {
//                                    updateMetadata()
//                                }
//                                print("From Away")
//                            }
//                            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
//                                DispatchQueue.main.async {
//                                    updateMetadata()
//                                }
//                                print("From Background")
//                            }
//                            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
//                                updateMetadata()
//                                print("From Foreground")
//                            }
//                            if !channelsExpanded {
//                                Spacer()
//                            }
//                            if authorButtonTapped {
//                                AuthorInfoView(video: viewModel.playerManager?.getCurrentVideo() ?? EMPTY_VIDEO, authorButtonTapped: $authorButtonTapped)
//                                    .transition(.move(edge: .bottom))
//                                    .transition(.opacity)
//                                    .animation(.easeOut)
//                            }
////                            } else {
////                                PageIndicator(currentIndex: $video_indices[channel_index], pageCount: viewModel.videos[activeChannel]?.count ?? 100, color: channelColor(channel: activeChannel), channel: $activeChannel)
////                                    .padding(.bottom)
////                                Spacer()
////                                ChannelSelectorView(activeChannel: $activeChannel, channel_index: $channel_index, isActive: $isChannel, video_indices: $video_indices, channelsExpanded: $channelsExpanded, dragOffset: $dragOffset)
////                                    .environmentObject(viewModel)
////                                    .transition(.move(edge: .bottom))
////                                    .animation(.easeInOut, value: isDiscover)
////                                    .offset(y: ((channelsExpanded ? 1 : 0) * dragOffset))
////                                    .frame(maxHeight: channelsExpanded ? .infinity : screenSize.height * 0.1 + abs(dragOffset))
////                                    .zIndex(1)
////                            }
//                            
//                        }
//                        
////                        if isChannel {
////
////                        } else {
////                            TextOverlayView(video_index: $video_indices[channel_index], channel_index: $channel_index, activeChannel: $activeChannel, isPlaying: $playing, videos: viewModel.videos, isActive: $isChannel)
////                                .environmentObject(authModel)
////                                .transition(.move(edge: .leading))
////                                .animation(.easeInOut)
////
////                        }
//                    }
//                    
//
////                    .gesture( BRING BACK FOR UP/DOWN SWIPE
//                }
//            }
//        }
//        .overlay(
//            Group {
//                if !hasSeenTutorial && !viewModel.isProcessing {
//                    withAnimation {
//                        TutorialView(showTutorial: $hasSeenTutorial)
//                    }
//                }
//            }
////                .ignoresSafeArea()
//        )
////        .simultaneousGesture(DragGesture()
////            .onChanged({ event in
////                dragOffset = event.translation.height < -90 ? -90 : event.translation.height
////
////            })
////            .onEnded({ event in
////                // Calculate new current index
////
////                DispatchQueue.global(qos: .userInitiated).async {
////
////
////                    let vel = event.predictedEndTranslation.height
////                    let distance = event.translation.height
////
////                    if vel <= -screenSize.height/3 || distance <= -screenSize.height/2 {
////                        channelsExpanded = true
////                    } else if vel >= screenSize.height/3 || distance >= screenSize.height/2 {
////                        channelsExpanded = false
////                    }
////                    dragOffset = 0
////                }
////            })
////        )
//    }
//    private func updateMetadata() {
//        if let video = viewModel.playerManager?.getCurrentVideo() {
//            viewModel.playerManager?.updateNowPlayingInfo(for: video)
//        }
//    }
//}
