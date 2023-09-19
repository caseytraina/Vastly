//
//  SearchVideoView.swift
//  Vastly
//
//  Created by Casey Traina on 9/18/23.
//

import Foundation
import SwiftUI
import Combine
import CoreMedia
import AVKit
import AVFoundation
import AudioToolbox

struct SearchVideoView: View {
    
    @EnvironmentObject var viewModel: VideoViewModel
    @EnvironmentObject var authModel: AuthViewModel

    var query: String
    
    @Binding var vids: [Video]
    @Binding var current_playing: Int
    
    @State private var cancellables = Set<AnyCancellable>()

    @State private var statusObserver: AnyCancellable?
    @State var isLoaded = false
    @State var videoFailed = false
    
    @Binding var isPlaying: Bool
    
    @State var videoMode: Bool = true
    @State var liked: Bool = false

    @State private var playerProgress: Double = 0
    @State private var playerDuration: CMTime = CMTime()
    @State private var playerTime: CMTime = CMTime()
    
    @State var previous = 0

    @State private var recent_change = false

    @State private var timeObserverToken: Any?
    @State private var endObserverToken: Any?
    @State private var timedPlayer: AVPlayer?

    @State private var bioExpanded = false
    
    @State var dragOffset: Double = 0.0
    
    @State var audioPlayer: AVAudioPlayer?

    @State var channel: Channel = FOR_YOU_CHANNEL // dummy channel
    
    @Binding var publisherIsTapped: Bool

    
    
    var body: some View {
            GeometryReader { geo in
                
                ScrollViewReader { proxy in

                        ScrollView {      
                            LazyVStack {
                                ForEach(0..<vids.count, id: \.self) { i in
                                    renderVStackVideo(
                                        geoWidth: geo.size.width,
                                        video: vids[i],
                                        next: i+1 < vids.count ? vids[i+1] : nil,
                                        i: i)
                                        .id(i)
                                        .frame(width: geo.size.width, height: geo.size.height)
                                        .clipped()
                                        .offset(y: dragOffset)
                                }
                            }
        //                        } // end of if
                        } // end scrollview
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scrollDisabled(true)
        //                    .id(activeChannel)
                        .clipped()
                        .onAppear {
                            viewModel.playerManager?.updateQueue(with: vids)
                            isPlaying = true

                            withAnimation(.easeOut(duration: 0.125)) {
                                proxy.scrollTo(current_playing, anchor: .top)
                            }
                            
                            viewModel.playerManager?.changeToIndex(to: current_playing, shouldPlay: isPlaying)
                            viewModel.playerManager?.updateNowPlayingInfo(for: getVideo(current_playing))
                            
                            previous = current_playing
                            trackAVStatus(for: getVideo(current_playing))
//                            play(current_playing)
    //                        viewModel.playerManager?.pauseAllOthers(except: getVideo(current_playing))

                        }
                        .onChange(of: current_playing) { newIndex in
                                
                            if newIndex >= vids.count {
                                current_playing = newIndex - 1
                            } else {
                                
                                withAnimation(.easeOut(duration: 0.125)) {
                                    proxy.scrollTo(newIndex, anchor: .top)
                                }
                                
                                recent_change = true
    //                            videoListNum = min(vids.count, videoListNum)
                                
                                trackAVStatus(for: getVideo(newIndex))
                                
                                viewModel.playerManager?.changeToIndex(to: newIndex, shouldPlay: isPlaying)
                                viewModel.playerManager?.updateNowPlayingInfo(for: getVideo(newIndex))

//                                pause(previous)
//                                play(newIndex)
                                
                                DispatchQueue.main.async {
                                    liked = false
                                    liked = videoIsLiked(current_playing)
                                }
                                
//                                if newIndex >= videoListNum - 2 {
//                                    videoListNum = min(videoListNum + 15, vids.count)
//                                }
                                
                                previous = newIndex
                            }
                        }
                    .frame(width: geo.size.width, height: geo.size.height)
                    
                }
            }
            .onChange(of: isPlaying) { newPlaying in
                if newPlaying {
                    play(current_playing)
                } else {
                    pause(current_playing)
                }
            }
            .gesture(DragGesture()
                .onChanged({ event in
                    dragOffset = event.translation.height
                })
                    .onEnded({ event in
                        // Calculate new current index
                        var changed = false
                                //vertical
                        
                        let vel = event.predictedEndTranslation.height
                        let distance = event.translation.height
                        
                        if vel <= -screenSize.height/4 || distance <= -screenSize.height/2 {
                            if current_playing + 1 <= vids.count {
                                current_playing += 1
                                
                            }
                        } else if vel >= screenSize.height/4 || distance >= screenSize.height/2 {
                            if current_playing > 0 {
                                current_playing -= 1
                            }
                        }
                        
                        dragOffset = 0

    //                                            }
                    })
            ) // end gesture
            .navigationBarItems(leading:
                HStack {
                    MyText(text: "Search for \"\(query)\"", size: screenSize.width * 0.05, bold: true, alignment: .leading, color: .white)
                    .padding(.horizontal)
                }
            )

    }
    
    private func renderVStackVideo(geoWidth: CGFloat, video: Video, next: Video?, i: Int) -> some View {
        VStack(alignment: .leading) {
            //                                if i == current_playing {
            HStack {
                
                if !videoMode {
                    VStack(alignment: .leading) {
                        MyText(text: "Audio autoplay is on", size: geoWidth * 0.04, bold: false, alignment: .leading, color: .white)
                        MyText(text: "Put Vastly in your pocket and go", size: geoWidth * 0.04, bold: false, alignment: .leading, color: Color("AccentGray"))
                    }
                    .padding(.horizontal)
                }
                
                
                Spacer()
                Toggle(isOn: $videoMode) {
                    
                }
                .toggleStyle(AudioToggleStyle(color: channel.color))
                .padding(.trailing, 40)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .frame(width: screenSize.width * 0.15)
            } // end hstack

            if (abs(i - current_playing) <= 1) {
                if let manager = viewModel.playerManager {

                    if videoFailed {
                        VideoFailedView()
                            .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT + PROGRESS_BAR_HEIGHT)
                    } else {
                        if isLoaded {
                            
                            VStack (spacing: 0) {
                                
                                ZStack {
                                    FullscreenVideoPlayer(videoMode: $videoMode, video: video, activeChannel: $channel)
                                        .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                                        .padding(0)
                                        .environmentObject(viewModel)

                                    if !videoMode {
                                        AudioOverlay(author: video.author, video: video, playing: $isPlaying)
                                            .environmentObject(viewModel)
                                    }
                                    if !isPlaying {
                                        Image(systemName: "play.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: screenSize.width * 0.15, weight: .light))
                                            .shadow(radius: 2.0)
                                            .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                                    }
                                }
                                .onTapGesture {
                                    isPlaying.toggle()
                                }

                                if i == current_playing {
                                    
                                    ProgressBar(value: $playerProgress, activeChannel: $channel, video: video)
                                        .frame(width: screenSize.width, height: PROGRESS_BAR_HEIGHT)
                                        .padding(0)
                                        .environmentObject(viewModel)
                                }
                            } // end vstack
                        }  else {
                            VideoThumbnailView(video: video)
                                .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT + PROGRESS_BAR_HEIGHT)
                        }
                    } // end if
                }
            } else {
                VideoLoadingView()
                    .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT + PROGRESS_BAR_HEIGHT)
            } // end abs if
            
            
            HStack(alignment: .top) {
                MyText(text: video.date ?? "", size: geoWidth * 0.03, bold: false, alignment: .leading, color: Color("AccentGray"))
                    .lineLimit(1)
                    .padding(.leading)
                
                Spacer()
                MyText(text: "\(playerTime.asString) / \(playerDuration.asString)", size: geoWidth * 0.03, bold: false, alignment: .leading, color: Color("AccentGray"))
                    .lineLimit(1)
                    .padding(.trailing)
            } // end hstack
            
            
            HStack {
                
                Button(action: {
                    withAnimation {
                        publisherIsTapped = true
                    }
                }, label: {
                    
                    
                    HStack(alignment: .center) {
                        if i == current_playing {
                            AsyncImage(url: AuthorURL(i)) { image in
                                image.resizable()
                            } placeholder: {
                                ZStack {
                                    Color("BackgroundColor")
                                    MyText(text: "?", size: geoWidth * 0.05, bold: true, alignment: .center, color: .white)
                                }
                            }
                            .frame(width: geoWidth * 0.125, height: geoWidth * 0.125)
                            .clipShape(RoundedRectangle(cornerRadius: 5)) // Clips the AsyncImage to a rounded
                            .padding(.leading)
                            //                                        .animation(.easeOut, value: activeChannel)
                            //                                        .transition(.opacity)
                            
                            MyText(text: video.author.name ?? "Unknown Author", size: geoWidth * 0.04, bold: true, alignment: .leading, color: .white)
                                .padding(0)
                                .lineLimit(2)
                            //                                            .animation(.easeOut, value: activeChannel)
                            //                                            .transition(.opacity)
                            Spacer()
                        }
                    }
                    
                })
                
                .zIndex(1)
                //                                    .padding(.bottom)
                
                Spacer()
                Image(systemName: liked ? "heart.fill" : "heart")
                    .foregroundColor(liked ? .red : .white)
                    .font(.system(size: screenSize.width * 0.05, weight: .medium))
                    .padding(.horizontal)
                    .onTapGesture {
                        DispatchQueue.main.async {
                            liked.toggle()
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            toggleLike(i)
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeOut, value: liked)
            } // end hstack
            .padding(.vertical, 5)
            .frame(width: geoWidth)
            VStack(alignment: .leading) {
                
                MyText(text: video.title, size: geoWidth * 0.05, bold: true, alignment: .leading, color: .white)
                    .lineLimit(2)
                    .padding(.horizontal, 15)
                
                    HStack {
                        //                                        VStack {
                        MyText(text: video.bio, size: geoWidth * 0.04, bold: false, alignment: .leading, color: Color("AccentGray"))
                            .truncationMode(.tail)
                            .padding(.horizontal, 15)
                            .lineLimit(bioExpanded ? 8 : 4)
                        Spacer()
                    }
                    .onTapGesture {
                        bioExpanded.toggle()
                    }
                .frame(maxWidth: geoWidth * 0.9)
                .padding(.bottom, 5)
                
                if let url = video.youtubeURL {
                    HStack {
                        FullEpisodeButton(video: video, isPlaying: $isPlaying)
//                                                    .frame(width: geo.size.width * 0.04)
                        Spacer()
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 15)
                }
                
                Spacer()
                //                                Spacer()
                if i == current_playing {
                    HStack {
                        Image(systemName: "arrow.down")
                            .foregroundColor(Color("AccentGray"))
                            .font(.system(size: geoWidth * 0.05, weight: .light))
                            .padding(.leading)
                        MyText(text: next != nil ? "\(next!.title)" : "Swipe up for more!", size: geoWidth * 0.03, bold: true, alignment: .leading, color: Color("AccentGray"))
                        Spacer()
                        

                        
                        
                    }
                    .frame(width: geoWidth)
                }
            } // end vstack
            .frame(width: geoWidth)

            
            
        }
    }
    
    
    private func videoIsLiked(_ i: Int) -> Bool {
        
        if let user = authModel.current_user {
            if let videos = user.liked_videos {
                return videos.contains(where: { $0 == getVideo(i).title })

            }
        }
        return false
    }
    
    private func getVideo(_ i: Int) -> Video {
//        if let vids = viewModel.videos[channel] {
//            if i < vids.count {
//                return vids[i]
//            }
//        }
        if i < vids.count {
            return vids[i]
        }
        return EMPTY_VIDEO
    }
    
    private func getNext() -> Video {
        return getVideo(current_playing + 1)
    }
    
    private func toggleLike(_ i: Int) {
        if let user = authModel.current_user {
            if let videos = user.liked_videos {
                if videoIsLiked(i) {
                    Task {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        await authModel.removeLikeFrom(getVideo(i))
                    }
                } else {
                    Task {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        await authModel.addLikeTo(getVideo(i))
                    }
                }
            }
        }
    }
    
    private func play(_ i: Int) {
//        if isPlaying {
        viewModel.playerManager?.getPlayer(for: getVideo(i)).play()
//        }
    }
    
    private func pause(_ i: Int) {
        viewModel.playerManager?.getPlayer(for: getVideo(i)).pause()
    }
    
    private func AuthorURL(_ i: Int) -> URL? {
        return viewModel.videos[channel]?[i].author.fileName
    }
    
    private func trackAVStatus(for video: Video) {
        statusObserver?.cancel()

        if let player = viewModel.playerManager?.getPlayer(for: video) {
            statusObserver = AnyCancellable(
                (player.currentItem?
                    .publisher(for: \.status)
                    .sink { status in
                        switch status {
                        case .unknown:
                            // Handle unknown status
                            print("UNKNOWN")
                            videoFailed = false

                            isLoaded = false
                        case .readyToPlay:
                            isLoaded = true
                            videoFailed = false
                            play(current_playing)
//                            viewModel.playerManager?.playCurrentVideo()
                            isPlaying = true
                        case .failed:
                            // Handle failed status
                            videoFailed = true
//                            viewModel.videos[activeChannel]?.remove(at: current_playing)
//                            videoListNum -= 1
//                            print("DELETED")
//                            nextVideo()
                            isLoaded = false
                        @unknown default:
                            // Handle other unknown cases
                            videoFailed = false
                            isLoaded = false
                        }
                    })!
            )
            
            switchedPlayer()
            observePlayer(to: player)
            
        }
    }
    
    private func switchedPlayer() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        viewModel.playerManager?.getPlayer(for: getVideo(current_playing))
            .publisher(for: \.rate)
            .sink { newRate in
                if newRate == 0 && !recent_change {
                    isPlaying = false
                } else {
                    isPlaying = true
                }
                viewModel.playerManager?.updateNowPlayingInfo(for: getVideo(current_playing))
                recent_change = false
            }
            .store(in: &cancellables)
    }
    
    private func playSound() {

        if let path = Bundle.main.path(forResource: "Blow", ofType: "aiff") {
            let soundUrl = URL(fileURLWithPath: path)
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundUrl)
                audioPlayer?.play()
            } catch {
                print("Error initializing AVAudioPlayer.")
            }
        }
    }
    
    private func observePlayer(to player: AVPlayer) {
                
//        DispatchQueue.global(qos: .userInitiated).async {
        print("Attached observer to \(player.currentItem)")
            
        player.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                DispatchQueue.main.async {
                    let duration = player.currentItem?.asset.duration
                    self.playerDuration = duration ?? CMTime(value: 0, timescale: 1000)
                    
                    timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1000), queue: .main) { time in
                        self.playerTime = time
                        self.playerProgress = time.seconds / (duration?.seconds ?? 1.0)
                        self.timedPlayer = player
                    }
                }
            }
        
        print("Started Observing Video")
        
        if let endObserverToken = endObserverToken {
            NotificationCenter.default.removeObserver(endObserverToken)
            self.endObserverToken = nil
        }
        
        endObserverToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            recent_change = true
            playSound()
            videoCompleted(for: getVideo(current_playing), with: authModel.user, profile: authModel.current_user)
            player.seek(to: CMTime.zero)

            player.pause()
            current_playing += 1;
//            recent_change = false
        }
    }
    
}

