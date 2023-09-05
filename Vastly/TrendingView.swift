//
//  TrendingView.swift
//  Vastly
//
//  Created by Casey Traina on 8/7/23.
//

import SwiftUI
import AVKit
import Combine

struct TrendingView: View {
    
    @EnvironmentObject var viewModel: VideoViewModel
    @EnvironmentObject var authModel: AuthViewModel
    
    @State var previous_index = 0
    
    @State var video: Video = EXAMPLE_VIDEO
    @Binding var videoMode: Bool

    @Binding var current_index: Int = 0
    
    @State var liked = false
    @State var bioExpanded = false
    @State var nextVideo = "Spotify's Origin Story"

    @State var videoListNum = 15
    
    @State var dragOffset: CGFloat = 0.0
    
    @State private var cancellables = Set<AnyCancellable>()
    @State private var statusObserver: AnyCancellable?

    @State var isLoaded = false
    @State var videoFailed = false
    @State var isPlaying = true
    @State var recent_change = true

    @State private var playerProgress: Double = 0
    @State private var playerDuration: CMTime = CMTime()
    @State private var playerTime: CMTime = CMTime()
    @State private var timeObserverToken: Any?
    @State private var timedPlayer: AVPlayer?

    @Binding var isDiscover: Bool
    
    @State var channel: Channel = .foryou
    
    @State private var endObserverToken: Any?
    
    var body: some View {
        ZStack {
//            Color(.black)
//                .ignoresSafeArea()
            GeometryReader { geo in

                ScrollViewReader { proxy in
                    ScrollView {
                        ForEach(viewModel.trendingVideos.indices.prefix(videoListNum)) { i in
                            VStack(alignment: .leading) {
                                Spacer()
                                
                                if abs(i-current_index) <= 1 {
                                    HStack {
                                        Spacer()
                                        Toggle(isOn: $videoMode) {
                                            
                                        }
                                        .toggleStyle(AudioToggleStyle(color: Channel.foryou.color))
                                        .padding(.trailing, 40)
                                        .padding(.bottom, 10)
                                        .frame(width: screenSize.width * 0.15)
                                    }
                                    if videoFailed {
                                        VideoFailedView()
                                    } else {
                                        if isLoaded {
                                            VStack(spacing: 0) {
                                                ZStack {
//                                                    FullscreenVideoPlayer(videoMode: $videoMode, index: i, activeChannel: $channel)
//                                                        .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
//                                                        .zIndex(0)
//                                                        .environmentObject(viewModel)
                                                    if !isPlaying {
                                                        Image(systemName: "play.fill")
                                                            .foregroundColor(.white)
                                                            .font(.system(size: screenSize.width * 0.15, weight: .light))
                                                            .shadow(radius: 2.0)
                                                            .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                                                    }
                                                    if !videoMode {
                                                        AudioOverlay(author: getCurrent().author, video: getCurrent(), playing: $isPlaying)
                                                            .environmentObject(viewModel)
                                                            .zIndex(1)
                                                    }
                                                }
                                                .onTapGesture {
                                                    isPlaying.toggle()
                                                }
                                                ProgressBar(value: $playerProgress, activeChannel: $channel, video: getCurrent())
                                                    .frame(width: screenSize.width, height: PROGRESS_BAR_HEIGHT)
                                                    .padding(0)
                                                    .environmentObject(viewModel)
                                                    .zIndex(2)
                                            }
                                        } else {
                                            VideoThumbnailView(video: viewModel.trendingVideos[i])
                                        }
                                    }
                                    
                                } else {
                                    VideoThumbnailView(video: viewModel.trendingVideos[i])
                                }
                                HStack(alignment: .top) {
                                    MyText(text: playerTime.asString, size: geo.size.width * 0.03, bold: false, alignment: .leading, color: Color("AccentGray"))
                                    Spacer()
                                    MyText(text: playerDuration.asString, size: geo.size.width * 0.03, bold: false, alignment: .leading, color: Color("AccentGray"))
                                }
                                .zIndex(1)
                                .padding(0)
                                
                                HStack {


                                    HStack(alignment: .center) {
                                        AsyncImage(url: AuthorURL(i)) { image in
                                            image.resizable()
                                        } placeholder: {
                                            ZStack {
                                                Color("BackgroundColor")
                                                MyText(text: "?", size: geo.size.width * 0.05, bold: true, alignment: .center, color: .white)
                                            }
                                        }
                                        .frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
                                        .clipShape(RoundedRectangle(cornerRadius: 5)) // Clips the AsyncImage to a rounded rectangle shape
//                                        .overlay(
////                                            RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 1) // Adds a rounded rectangle border
//                                        )
                                        .padding(.leading)

                                        
                                        MyText(text: viewModel.trendingVideos[i].author.name ?? "Unknown Author", size: geo.size.width * 0.04, bold: true, alignment: .leading, color: .white)
                                            .padding(0)
                                            .lineLimit(2)
                                        Spacer()
                                    }
                                    .zIndex(1)
//                                    .padding(.bottom)

                                    Spacer()
                                    Image(systemName: liked ? "heart.fill" : "heart")
                                        .foregroundColor(liked ? .red : .white)
                                        .font(.system(size: screenSize.width * 0.05, weight: .medium))
                                        .padding()
                                        .onTapGesture {
                                            DispatchQueue.main.async {
                                                liked.toggle()
                                                //                                            toggleLike(i)
                                            }
                                        }
                                        .frame(maxWidth: geo.size.width * 0.1)
                                        .transition(.opacity)
                                        .animation(.easeOut, value: liked)
                                }
                                .frame(width: screenSize.width)
                                VStack(alignment: .leading) {
                                    MyText(text: viewModel.trendingVideos[i].title, size: geo.size.width * 0.05, bold: true, alignment: .leading, color: .white)
                                        .lineLimit(2)
                                    HStack {
                                        MyText(text: viewModel.trendingVideos[i].bio, size: geo.size.width * 0.04, bold: false, alignment: .leading, color: Color("AccentGray"))
                                            .truncationMode(.tail)
                                            .lineLimit(bioExpanded ? 8 : 4)
                                            .padding(.bottom, geo.size.height * 0.05)
                                            .onTapGesture {
                                                withAnimation {
                                                    bioExpanded.toggle()
                                                    
                                                }
                                            }
                                            .frame(maxWidth: geo.size.width * 0.9)
                                        Spacer()
                                    }
                                }
                                Spacer()
                                MyText(text: i < min(videoListNum, viewModel.trendingVideos.count)  - 1 ? "Next Up: \(getNext().title)" : "Swipe for more!", size: geo.size.width * 0.03, bold: false, alignment: .leading, color: Color("AccentGray"))
                                    .lineLimit(2)
                                
                            }
                            .frame(width: geo.size.width, height: geo.size.height)
//                            .frame(maxHeight: .infinity)
                            .id(i)

                        }
                        .opacity(opacityFor(dragOffset: dragOffset))

                    }
                    .offset(y: dragOffset)

                    .frame(maxWidth: .infinity, maxHeight: .infinity) // First make your ScrollView take as much space as it can

//                    .frame(height: screenSize.height*0.8)

                    .onAppear {
                        previous_index = current_index
                        viewModel.playerManager?.getPlayer(for: viewModel.trendingVideos[current_index]).play()
                        viewModel.playerManager?.pauseCurrentVideo()
                        switchedPlayer()
//                        withAnimation {
                            proxy.scrollTo(current_index, anchor: .center)
//                        }
                        trackAVStatus(for: viewModel.trendingVideos[current_index])
                        observePlayer(to: viewModel.playerManager?.getPlayer(for: getCurrent()) ?? AVPlayer())
                        viewModel.playerManager?.updateNowPlayingInfo(for: getCurrent())
                    }
                    
                    .onChange(of: current_index) { new_index in
//                        proxy.scrollTo(
                        

                        
                        print("Changed Index")
                        recent_change = true
                        withAnimation {
                            proxy.scrollTo(new_index, anchor: .center)
                        }
                        observePlayer(to: viewModel.playerManager?.getPlayer(for: viewModel.trendingVideos[new_index]) ?? AVPlayer())
                        viewModel.playerManager?.updateNowPlayingInfo(for: getCurrent())
                        switchedPlayer()
                        
                        viewModel.playerManager?.getPlayer(for: viewModel.trendingVideos[previous_index]).pause()
                        viewModel.playerManager?.getPlayer(for: video).play()
                        if new_index >= videoListNum-1 {
                            videoListNum += 10
                            if viewModel.trendingVideos.count < videoListNum {
                                viewModel.addTrendingVideos()
                            }
//                            videoListNum = viewModel.trendingVideos.count
                        }
                        previous_index = new_index
                        trackAVStatus(for: viewModel.trendingVideos[new_index])


                        
                        recent_change = false


                    }
                    .scrollDisabled(true)
                    .gesture(DragGesture()
                        .onChanged({ event in
                            dragOffset = event.translation.height
                        })
                        .onEnded({ event in
                            // Calculate new current index
                            
                            DispatchQueue.global(qos: .userInitiated).async {

                                
                                let vel = event.predictedEndTranslation.height
                                let distance = event.translation.height
                                
                                if vel <= -screenSize.height/2 || distance <= -screenSize.height/2 {
                                    if current_index + 1 <= min(videoListNum, viewModel.trendingVideos.count) {
                                        current_index += 1
                                    }
                                } else if vel >= screenSize.height/2 || distance >= screenSize.height/2 {
                                    if current_index > 0 {
                                        current_index -= 1
                                    }
                                }
                                dragOffset = 0
                            }
                        })
                    )
                    .onChange(of: isDiscover) { newDiscover in
                        if newDiscover {
                            viewModel.playerManager?.getPlayer(for: viewModel.trendingVideos[current_index]).play()
                            viewModel.playerManager?.updateNowPlayingInfo(for: getCurrent())
                        } else {
                            viewModel.playerManager?.getPlayer(for: viewModel.trendingVideos[current_index]).pause()
                        }
                    }
                    .onChange(of: isPlaying) { newPlaying in
                        if newPlaying {
                            viewModel.playerManager?.getPlayer(for: viewModel.trendingVideos[current_index]).play()
                        } else {
                            viewModel.playerManager?.getPlayer(for: viewModel.trendingVideos[current_index]).pause()
                        }
                    }
                }

                .id(videoListNum)
            }
        }
    }
    
    private func AuthorURL(_ i: Int) -> URL? {
        return viewModel.trendingVideos[i].author.fileName
    }
    
    private func getNext() -> Video {
        return viewModel.trendingVideos[current_index + 1]
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
        }
    }
    
    func opacityFor(dragOffset: CGFloat) -> Double {
        let baseOpacity: Double = 1.0
        let fadeFactor: Double = 0.001 // Adjust this value to change the rate of fading
        let offsetDistance = Double(abs(dragOffset))
        
        let newOpacity = baseOpacity - (offsetDistance * fadeFactor)
        
        return max(newOpacity, 0) // Ensuring opacity doesn't go below 0
    }
    
    private func videoIsLiked(_ i: Int) -> Bool {
        
        if let user = authModel.current_user {
            if let videos = user.liked_videos {
                return videos.contains(where: { $0 == viewModel.trendingVideos[current_index].title })

            }
        }
        return false
    }
    
    private func toggleLike(_ i: Int) {
        if let user = authModel.current_user {
            if let videos = user.liked_videos {
                if videoIsLiked(i) {
                    Task {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        await authModel.removeLikeFrom(getCurrent())
                    }
                } else {
                    Task {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        await authModel.addLikeTo(getCurrent())
                    }
                }
            }
        }
    }
    
    private func getCurrent() -> Video {
        return viewModel.trendingVideos[current_index]
    }
    
    private func switchedPlayer() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        viewModel.playerManager?.getPlayer(for: getCurrent())
            .publisher(for: \.rate)
            .sink { newRate in
                if newRate == 0 && !recent_change {
                    isPlaying = false
                } else {
                    isPlaying = true
                }
                viewModel.playerManager?.updateNowPlayingInfo(for: getCurrent())
                recent_change = false
            }
            .store(in: &cancellables)
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

            videoCompleted(for: getCurrent(), with: authModel.user)
            player.seek(to: CMTime.zero)

            player.pause()
            current_index += 1;
//            recent_change = false

        }
    }
    
    private func attachObservers(to player: AVPlayer) {

            
//            stalledObserverToken = NotificationCenter.default.addObserver(
//                forName: .AVPlayerItemPlaybackStalled,
//                object: player.currentItem,
//                queue: .main
//            ) { _ in
//                if recent_change {
//                    isPlaying = true
//                } else {
//                    isPlaying = false
//                }
//                recent_change = false
//            }
//

        
//        }
    }
    
//    private func removeObservers(from player: AVPlayer) {
//        DispatchQueue.global(qos: .userInitiated).async {
//
////            if timedPlayer != nil {
////                if let timeObserverToken = timeObserverToken {
////                    self.timedPlayer?.removeTimeObserver(timeObserverToken)
////                    self.timeObserverToken = nil
////                    self.timedPlayer = nil
////                }
////            }
//            print("removed observer to \(player.currentItem)")
//
//
//            if let endObserverToken = endObserverToken {
//                NotificationCenter.default.removeObserver(endObserverToken)
//                self.endObserverToken = nil
//            }
//
//            if let stalledObserverToken = stalledObserverToken {
//                NotificationCenter.default.removeObserver(stalledObserverToken)
//                self.stalledObserverToken = nil
//            }
//        }
//    }
    
    
}

//struct TrendingView_Previews: PreviewProvider {
//    static var previews: some View {
//        TrendingView()
//    }
//}
