//
//  CatalogVerticalVideoView.swift
//  Vastly
//
//  Created by Michael Murray on 10/20/23

import SwiftUI
import Combine
import CoreMedia
import AVKit
import AVFoundation
import AudioToolbox

struct CatalogVideoView: View {
    
    @EnvironmentObject var viewModel: CatalogViewModel
    @EnvironmentObject var authModel: AuthViewModel

    var channel: ChannelVideos
    @State private var cancellables = Set<AnyCancellable>()

    @State private var statusObserver: AnyCancellable?
    @State var isLoaded = true // TEMPORARY BEFORE STATUS OBSERVERS ADDED
    @State var videoFailed = false

    @State var videoListNum = 1
    
    @Binding var isPlaying: Bool
    
    @State var videoMode: Bool = true
    @State var liked: Bool = false

    @State private var playerProgress: Double = 0
    @State private var playerDuration: CMTime = CMTime()
    @State private var playerTime: CMTime = CMTime()

    @State private var recent_change = false

    @State private var timeObserverToken: Any?
    @State private var endObserverToken: Any?
    @State private var timedPlayer: AVPlayer?

    @State private var bioExpanded = false
    
    @Binding var dragOffset: Double
    
    @State var audioPlayer: AVAudioPlayer?
    @State var shareURL: URL?
    @Binding var publisherIsTapped: Bool

    var body: some View {
        if channel.videos.isEmpty {
            emptyVideos()
        } else {
            ScrollViewReader { proxy in
                GeometryReader { geo in
                    ScrollView {
                        LazyVStack {
                            ForEach(Array(channel.videos.enumerated()), id: \.offset) { i, vid in
                                renderVStackVideo(
                                    geoWidth: geo.size.width,
                                    geoHeight: geo.size.height,
                                    video: vid,
                                    next: viewModel.catalog.peekNextVideo(),
                                    i: i)
                            }
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scrollDisabled(true)
                    .clipped()
                    .onAppear {
                        let currentVideoIndex = self.viewModel.catalog.currentVideoIndex()
                        withAnimation(.easeOut(duration: 0.125)) {
                            proxy.scrollTo(currentVideoIndex, anchor: .top)
                        }
                        if let currentVideo = self.viewModel.catalog.currentVideo {
                            // self.trackAVStatus(for: currentVideo)
                            self.shareURL = videoShareURL(currentVideo)
                        }
                    }
                    .onChange(of: self.viewModel.catalog.currentVideo) { newVideo in
                        let newVideoIndex = self.viewModel.catalog.currentVideoIndex()
                        withAnimation(.easeOut(duration: 0.125)) {
                            proxy.scrollTo(newVideoIndex, anchor: .top)
                        }
                        
                        if let newVideo = newVideo {
                            // self.trackAVStatus(for: newVideo)
                            DispatchQueue.main.async {
                                liked = false
                                liked = videoIsLiked(newVideo)
                            }
                            self.shareURL = videoShareURL(newVideo)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
    }
        
    private func emptyVideos() -> some View {
        ZStack {
            Color("BackgroundColor")
            MyText(text: "It seems you've seen all these videos. Try a new channel!", size: screenSize.width * 0.05, bold: true, alignment: .center, color: .white)
        }
        .frame(width: screenSize.width, height: screenSize.height * 0.8)
    }
    
    private func renderVStackVideo(geoWidth: CGFloat, geoHeight: CGFloat, video: Video, next: Video?, i: Int) -> some View {
        VStack(alignment: .leading) {
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
//                .toggleStyle(AudioToggleStyle(color: self.viewModel.catalog.currentChannel?.channel.color))
                .padding(.trailing, 40)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .frame(width: screenSize.width * 0.15)
            } // end hstack
            if videoFailed {
                VideoFailedView()
                    .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)// + PROGRESS_BAR_HEIGHT)
            } else {
                if isLoaded {
                    ZStack {
                        ZStack {
                            FullscreenVideoPlayer(videoMode: $videoMode,
                                                  video: video)
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
                        ProgressBar(value: $playerProgress,
                                    video: video, isPlaying: $isPlaying)
                            .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                            .padding(0)
                            .environmentObject(viewModel)
                    }
                    .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                }  else {
                    VideoThumbnailView(video: video)
                        .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                }
            }

            VStack(alignment: .center) {
                
                HStack(alignment: .top) {
                    MyText(text: video.date ?? "", size: geoWidth * 0.03, bold: false, alignment: .leading, color: Color("AccentGray"))
                        .lineLimit(1)
                        .padding(.leading)
                    
                    Spacer()
                    MyText(text: "\(playerTime.asString) / \(playerDuration.asString)", size: geoWidth * 0.03, bold: false, alignment: .leading, color: Color("AccentGray"))
                        .lineLimit(1)
                        .padding(.trailing)
                } // end hstack
//                .frame(width: geoWidth)
                
                
                VStack {
                    
                    HStack {
                        
                        MyText(text: video.title, size: 20, bold: true, alignment: .leading, color: .white)
                            .lineLimit(1)
                        
                        Spacer()
                        Image(systemName: liked ? "plus.square.fill.on.square.fill" : "plus.square.on.square")
                            .foregroundColor(liked ? .red : .white)
                            .font(.system(size: 18, weight: .medium))
                        //                        .padding(.horizontal)
                            .onTapGesture {
                                
                                DispatchQueue.main.async {
                                    liked.toggle()
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                    toggleLike(video)
                                }
                                
                            }
                            .transition(.opacity)
                            .animation(.easeOut, value: liked)
                    } // end hstack
//                    .frame(width: geoWidth)
                    
                    HStack {
                        Button(action: {
                            withAnimation {
                                publisherIsTapped = true
                            }
                        }, label: {
                            MyText(text: video.author.name ?? "Unknown Author", size: 16, bold: true, alignment: .leading, color: .gray)
                                .brightness(0.25)
                                .padding(0)
                                .lineLimit(1)
                        })
                        Spacer()
                    }
                    
                    
                }
                .padding(.vertical, 5)
//                .frame(width: geoWidth)
                //            .padding(.horizontal, 15)
                
                VStack(alignment: .leading) {
                    
                    MyText(text: video.bio, size: 16, bold: false, alignment: .leading, color: Color("AccentGray"))
                        .truncationMode(.tail)
                        .lineLimit(bioExpanded ? 8 : 2)
                        .onTapGesture {
                            withAnimation {
                                bioExpanded.toggle()
                            }
                        }
                        .padding(.vertical, 5)
                    
                    HStack (alignment: .center) {
                        if let _ = video.youtubeURL {
                            
                            FullEpisodeButton(video: video, isPlaying: $isPlaying)
//                                .frame(maxWidth: geoWidth * 0.5, maxHeight: geoHeight * 0.075)
                                .padding(.trailing, 5)

                        }
                        if let shareURL {
                            ShareLink(item: shareURL) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18, weight: .medium))
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    Spacer()
                    
                }
            }
            .padding(.horizontal, 10)
        }
        .id(i)
        .frame(width: geoWidth, height: geoHeight)
        .clipped()
        .offset(y: channel == viewModel.currentChannel ? dragOffset : 0.0)
    }
    
    private func videoIsLiked(_ video: Video) -> Bool {
        if let user = authModel.current_user {
            if let videos = user.likedVideos {
                return videos.contains(where: { $0 == video.id })
            }
        }
        return false
    }
    
    private func videoShareURL(_ video: Video) -> URL {
        let string = "vastlyapp://open-video?id=\(String(video.id.replacingOccurrences(of: " ", with: "%20")))"
        return URL(string: string) ?? EMPTY_VIDEO.url!
    }
    
    private func toggleLike(_ video: Video) {
        if let user = authModel.current_user {
            if let videos = user.likedVideos {
                if videoIsLiked(video) {
                    Task {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        await authModel.removeLikeFrom(video)
                    }
                } else {
                    Task {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        await authModel.addLikeTo(video)
                    }
                }
            }
        }
    }
    
//    private func trackAVStatus(for video: Video) {
//        statusObserver?.cancel()
//
//        if let player = viewModel.playerManager?.getPlayer(for: video) {
//            statusObserver = AnyCancellable(
//                (player.currentItem?
//                    .publisher(for: \.status)
//                    .sink { status in
//                        switch status {
//                        case .unknown:
//                            // Handle unknown status
//                            print("UNKNOWN")
//                            videoFailed = false
//
//                            isLoaded = false
//                        case .readyToPlay:
//                            isLoaded = true
//                            videoFailed = false
////                            isPlaying = true
//                            viewModel.playerManager?.playCurrentVideo()
//                        case .failed:
//                            // Handle failed status
//                            videoFailed = true
////                            viewModel.videos[activeChannel]?.remove(at: current_playing)
////                            videoListNum -= 1
////                            print("DELETED")
////                            nextVideo()
//                            isLoaded = false
//                        @unknown default:
//                            // Handle other unknown cases
//                            videoFailed = false
//                            isLoaded = false
//                        }
//                    })!
//            )
//            
//            switchedPlayer()
//            observePlayer(to: player)
//            
//        }
//    }
//    
//    private func switchedPlayer() {
//        cancellables.forEach { $0.cancel() }
//        cancellables.removeAll()
//        viewModel.playerManager?.getPlayer(for: getVideo(current_playing))
//            .publisher(for: \.rate)
//            .sink { newRate in
//                if newRate == 0 && !recent_change {
//                    isPlaying = false
//                } else {
//                    isPlaying = true
//                }
//                viewModel.playerManager?.updateNowPlayingInfo(for: getVideo(current_playing))
//                recent_change = false
//            }
//            .store(in: &cancellables)
//    }
//    
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
    
//    private func observePlayer(to player: AVPlayer) {
//                
////        DispatchQueue.global(qos: .userInitiated).async {
//        print("Attached observer to \(player.currentItem)")
//            
//        player.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
//                DispatchQueue.main.async {
//                    let duration = player.currentItem?.asset.duration
//                    self.playerDuration = duration ?? CMTime(value: 0, timescale: 1000)
//                    
//                    timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1000), queue: .main) { time in
//                        self.playerTime = time
//                        self.playerProgress = time.seconds / (duration?.seconds ?? 1.0)
//                        self.timedPlayer = player
//                    }
//                }
//            }
//        
//        print("Started Observing Video")
//        
//        if let endObserverToken = endObserverToken {
//            NotificationCenter.default.removeObserver(endObserverToken)
//            self.endObserverToken = nil
//        }
//        
//        endObserverToken = NotificationCenter.default.addObserver(
//            forName: .AVPlayerItemDidPlayToEndTime,
//            object: player.currentItem,
//            queue: .main
//        ) { _ in
//            recent_change = true
//            playSound()
//            videoCompleted(for: getVideo(current_playing), with: authModel.user, profile: authModel.current_user)
//            player.seek(to: CMTime.zero)
//
//            player.pause()
//            current_playing += 1;
////            recent_change = false
//        }
//    }
//    
}

