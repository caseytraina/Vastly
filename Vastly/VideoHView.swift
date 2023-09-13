//
//  VideoView.swift
//  Vastly
//
//  Created by Casey Traina on 5/9/23.
//

import SwiftUI
import AVKit
import MediaPlayer
import Combine
import Firebase
import FirebaseCore

struct VideoHView: View {
    
    @EnvironmentObject var viewModel: VideoViewModel
    @EnvironmentObject var authModel: AuthViewModel

    var videos: [Channel : [Video]]
    var channel: Channel

    @Binding var current_playing: Int
    @Binding var activeChannel: Channel
    @Binding var isPlaying: Bool

    @State var videoFailed = false
    
//    @State var player = AVQueuePlayer()
    @State var bioExpanded = false
    @State var liked = false

    @State var autoplayed = 0
    
    @State var shouldSkip = true
    @State var previous_playing = 0
    @State var previous_channel: Channel = FOR_YOU_CHANNEL
    
    @State private var cancellables = Set<AnyCancellable>()
    @State private var statusObserver: AnyCancellable?
    
    @State private var timeObserverToken: Any?
    @State private var stalledObserverToken: Any?
    @State private var endObserverToken: Any?
    @State private var timedPlayer: AVPlayer?
    
    @State var recent_change = false

    @State var startTime = Date()
    @State var endTime = Date()
    
    @State var isLoaded = false

    @Binding var isActive: Bool
    
    @State private var playerProgress: Double = 0
    @State private var playerDuration: CMTime = CMTime()
    @State private var playerTime: CMTime = CMTime()

    @Binding var videoMode: Bool
    @Binding var authorButtonTapped: Bool

    @State private var videoListNum = 25
    
    init(videos: [Channel : [Video]], channel: Channel, current_playing: Binding<Int>, activeChannel: Binding<Channel>, isPlaying: Binding<Bool>, isActive: Binding<Bool>, videoMode: Binding<Bool>, authorButtonTapped: Binding<Bool>) {
        self._current_playing = current_playing
        self._activeChannel = activeChannel
        self._isPlaying = isPlaying
        self._isActive = isActive
        self._videoMode = videoMode
        self._authorButtonTapped = authorButtonTapped
        
        self.videos = videos
        self.channel = channel
        
        _videoListNum = State(initialValue: min(videos[channel]?.count ?? 100, 25))
    }
    
    var body: some View {

        GeometryReader { geo in
            // VIDEO SCROLL VIEW
            VStack {
                if let vids = viewModel.videos[channel] {
                    HStack(alignment: .center, spacing: 0) {
                        
                        ForEach(vids.indices.prefix(videoListNum)) { i in
                            VStack(alignment: .leading) {
                                
                                if (abs(i - current_playing) <= 1 && channel == activeChannel) || (i == current_playing) {
                                    if let manager = viewModel.playerManager {
                                        if videoFailed {
                                            VideoFailedView()
                                        } else {
                                            if isLoaded {
                                                
                                                VStack (spacing: 0) {
                                                    ZStack {
//                                                        FullscreenVideoPlayer(player: manager.getPlayer(for: vids[i]), videoMode: $videoMode)
//                                                            .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
//                                                            .padding(0)
                                                        if !videoMode {
                                                            AudioOverlay(author: getVideo(i: i, in: activeChannel).author, video: getVideo(i: i, in: activeChannel), playing: $isPlaying)
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
                                                    .onTapGesture(count: 2) {
                                                        DispatchQueue.main.async {
                                                            toggleLike(i)
                                                        }
                                                    }
                                                    if i == current_playing {
                                                        
//                                                        ProgressBar(value: $playerProgress, activeChannel: $activeChannel, video: getVideo(i: i, in: activeChannel))
//                                                            .frame(width: screenSize.width, height: PROGRESS_BAR_HEIGHT)
//                                                            .padding(0)
//                                                            .environmentObject(viewModel)
                                                    }
                                                }
                                                
                                            } else {
                                                VideoThumbnailView(video: vids[i])
                                            }
                                        }
                                    }
                                } else {
                                    VideoLoadingView()
                                }
                                if !isActive {

                                HStack {
                                    MyText(text: getInfo(field: .title, i: i), size: geo.size.width * 0.045, bold: true, alignment:
                                            .leading, color: .white)
                                    .lineLimit(2)
                                    .truncationMode(.tail)
                                    .frame(alignment: .leading)
                                    Spacer()
                                    Image(systemName: liked ? "heart.fill" : "heart")
                                        .foregroundColor(liked ? .red : .white)
                                        .font(.system(size: screenSize.width * 0.05, weight: .medium))
                                        .padding()
                                        .onTapGesture {
                                            DispatchQueue.main.async {
                                                liked.toggle()
                                                toggleLike(i)
                                            }
                                        }
                                        .transition(.opacity)
                                        .animation(.easeOut, value: liked)
                                }
                                VStack(alignment: .leading
                                       , spacing: 2.0) {
                                        HStack {
                                            MyText(text: getInfo(field: .author, i: i), size: geo.size.width * 0.04, bold: false, alignment: .leading, color: Color("AccentGray"))
                                                .truncationMode(.tail)
                                                .lineLimit(2)
                                            Spacer()
                                            MyText(text: getInfo(field: .date, i: current_playing), size: geo.size.width * 0.04, bold: false, alignment: .leading, color: Color("AccentGray"))
                                            
                                        }
                                    }
                                    
                                    HStack {
                                        if isActive{
                                            MyText(text: authorButtonTapped ? "see less" : "see more", size: geo.size.width * 0.04, bold: false, alignment: .leading, color: .white)
                                                .onTapGesture {
                                                    authorButtonTapped.toggle()
                                                }
                                        }
                                        Spacer()
//                                        MyText(text: getInfo(field: .date, i: current_playing), size: geo.size.width * 0.04, bold: false, alignment: .leading, color: Color("AccentGray"))
                                    }
                                    .padding(.bottom)

//                                    Spacer()
                                }

                                
                                if !isActive {
                                    
                                    MyText(text: getInfo(field: .bio, i: i), size: geo.size.width * 0.04, bold: false, alignment: .leading, color: Color("AccentGray"))
                                        .truncationMode(.tail)
                                        .lineLimit(bioExpanded ? 8 : 3)
                                        .padding(.bottom, geo.size.height * 0.05)
                                        .onTapGesture {
                                            withAnimation {
                                                bioExpanded.toggle()
                                                
                                            }
                                        }
//                                        .transition(.move(edge: .trailing))
//                                        .animation(.easeInOut)
                                }
                                Spacer()
                            }
                        }
                    }
                    .onDisappear {
                        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemPlaybackStalled, object: viewModel.playerManager?.getPlayer(for: videos[channel]![current_playing]).currentItem)
                    }
                    .onAppear {
                        previous_playing = current_playing
                        if channel == activeChannel {
                            if let player = viewModel.playerManager?.getPlayer(for: getVideo(i: current_playing, in: activeChannel)) {
                                attachObservers(to: player)
                            }

                            play()
                            trackAVStatus(for: getVideo(i: current_playing, in: activeChannel))

                            startTime = Date()

                            viewModel.playerManager?.current_index = current_playing
                            viewModel.playerManager?.getPlayer(for: getVideo(i: current_playing, in: activeChannel))
                                .publisher(for: \.rate)
                                .sink { newRate in
                                    if newRate == 0 && !recent_change {
                                        isPlaying = false
                                    } else {
                                        isPlaying = true
                                    }
//                                    viewModel.playerManager?.updateNowPlayingInfo(for: getVideo(i: current_playing, in: activeChannel))
                                    recent_change = false
                                }
                                .store(in: &cancellables)
                            
                            videoWatched(for: getVideo(i: current_playing, in: activeChannel), with: authModel.user, profile: authModel.current_user)
                            channelTapped(for: activeChannel, with: authModel.user)
                            viewModel.playerManager?.updateNowPlayingInfo(for: getVideo(i: current_playing, in: activeChannel))
                            
                        }

                    }
//                    .id(videoListNum)
//                    .modifier(ScrollingHStackModifier(items: $videoListNum, itemWidth: VIDEO_WIDTH, itemSpacing: 0, current: $current_playing))
                    .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { notification in
                        if channel == activeChannel {
                            handleInterruption(notification: notification)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .onChange(of: current_playing) { newIndex in
                        if channel == activeChannel {
                            if let oldPlayer = viewModel.playerManager?.getPlayer(for: getVideo(i: previous_playing, in: activeChannel)) {
                                removeObservers(from: oldPlayer)
                            }
                            if let cur = currentPlayer() {
                                attachObservers(to: cur)
                            }
                            
                            if newIndex >= (videoListNum - 2) {
                                print("updated videoList")
                                videoListNum = min(videoListNum + 15, videos[activeChannel]?.count ?? 1000)
                            }
                            
                            DispatchQueue.main.async {
                                authorButtonTapped = false
                            }
                            
                            endTime = Date()
                            
                            let duration = viewModel.playerManager?.getPlayer(for: getVideo(i: previous_playing, in: activeChannel)).currentTime().seconds
                            
//                            logWatchTime(from: startTime, to: endTime, for: getVideo(i: previous_playing, in: activeChannel), time: (viewModel.playerManager?.getPlayer(for: getVideo(i: previous_playing, in: activeChannel)).currentItem!.duration.seconds) ?? 0.0, watched: duration, with: authModel.user, profile: authModel.current_user)
                            recent_change = true
                            trackAVStatus(for: getVideo(i: newIndex, in: activeChannel))
                            print("Checking", newIndex, activeChannel)
                            viewModel.playerManager?.changeToIndex(to: newIndex, shouldPlay: isPlaying)
//
                            startTime = Date()
                            
//                            if let prev = previousPlayerFromChannel() {
//                                removeObservers(from: prev)
//                            }
                            
                            
                            previous_playing = newIndex
                            videoWatched(for: getVideo(i: newIndex, in: activeChannel), with: authModel.user, profile: authModel.current_user)
                            switchToNewPlayer(getVideo(i: newIndex, in: activeChannel))
                            recent_change = false
                            liked = videoIsLiked(newIndex)
//                            viewModel.playerManager?.updateNowPlayingInfo(for: getVideo(i: newIndex, in: activeChannel))

                        }
                        
                    }
                    .onChange(of: activeChannel) { newChannel in
                        pause()
                        
                        if newChannel == channel {
                            
                            
                            DispatchQueue.main.async {
                                authorButtonTapped = false
                            }
                            endTime = Date()
                            
                            let duration = viewModel.playerManager?.getPlayer(for: getVideo(i: current_playing, in: previous_channel)).currentTime().seconds
                            
//                            logWatchTime(from: startTime, to: endTime, for: getVideo(i: current_playing, in: previous_channel), time: (viewModel.playerManager?.getPlayer(for: getVideo(i: current_playing, in: previous_channel)).currentItem!.duration.seconds) ?? 0.0, watched: duration, with: authModel.user, profile: authModel.current_user)
                            
                            recent_change = true
                        
                            print("Checking", current_playing, newChannel)
                            viewModel.playerManager?.changeToChannel(to: newChannel, shouldPlay: isPlaying, newIndex: current_playing)
                            
                            startTime = Date()
                            channelTapped(for: newChannel, with: authModel.user)
                            
                            trackAVStatus(for: getVideo(i: current_playing, in: newChannel))
                            switchToNewPlayer(getVideo(i: current_playing, in: newChannel))

                            recent_change = false
                            if let cur = currentPlayer() {
                                attachObservers(to: cur)
                            }
                            
                            previous_channel = newChannel
                            liked = videoIsLiked(current_playing)

//                                authorButtonTapped = false
                        }
                    }
                    .frame(width:  VIDEO_WIDTH)
                    .onChange(of: isPlaying) { newPlaying in
                        
                        if newPlaying {
                            play()
                        } else {
                            pause()
                        }
                    }
                    
                }
                
            }

            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
    enum Field {
        case channel, title, bio, author, date
    }
    
    private func getVideo(i: Int, in channel: Channel) -> Video {
        
        var video = EMPTY_VIDEO
        
        if let vids = videos[channel] {
            if i < vids.count && !vids.isEmpty {
                video = vids[i]
            }
        }
        return video
    }
    
    func switchToNewPlayer(_ video: Video) {
            
        // Cancel all existing subscriptions.
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        // Start a new subscription.
        viewModel.playerManager?.getPlayer(for: video)
            .publisher(for: \.rate)
            .sink { newRate in
                if newRate == 0 && !recent_change {
                    isPlaying = false
                } else {
                    isPlaying = true
                }
                viewModel.playerManager?.updateNowPlayingInfo(for: getVideo(i: current_playing, in: activeChannel))
                recent_change = false
            }
            .store(in: &cancellables)
    }
    
    private func getInfo(field: Field, i: Int) -> String {
        if let channelVideos = videos[activeChannel], i < channelVideos.count {
            let video = channelVideos[i]
            switch field {
            case .channel:
                return channel.title
            case .title:
                return video.title
            case .author:
                return video.author.name ?? ""
            case .bio:
                return video.bio
            case .date:
                return video.date ?? ""
            }
            
        }
        return "No data for \(activeChannel) Channel"
    }
    
    enum SeekDirection {
        case forward
        case backward
    }
    
    private func skip(seconds: Double, direction: SeekDirection) {
        
        let skip = direction == .forward ? seconds : seconds * -1
        
        let player = viewModel.playerManager?.getPlayer(for: getVideo(i: current_playing, in: activeChannel))
        
        guard let duration  = player?.currentItem?.duration else {
            return
        }
        
        let playerCurrentTime = CMTimeGetSeconds(player?.currentTime() ?? CMTime.zero)
        let newTime = playerCurrentTime + skip
        if newTime < (CMTimeGetSeconds(duration)) {
            let time2: CMTime = CMTimeMake(value: Int64(newTime*1000), timescale: 1000)
            player?.seek(to: time2, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }
    
    private func handleInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Interruption began, take appropriate actions (e.g. save state, update user interface)
            pause()
        case .ended:
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // Interruption ended, and the system suggests that you should resume audio
                    // Here you can resume your audio and refresh your metadata
                    play()
                }
            }
        default:
            play()
        }
    }
    
    
    private func play() {
        viewModel.playerManager?.playCurrentVideo()
    }
    
    private func pause() {
        viewModel.playerManager?.pauseCurrentVideo()
    }
    
    private func nextVideo() {
        current_playing += 1;
    }
    
    private func previousVideo() {
        current_playing -= 1;
    }
    
    private func videoIsLiked(_ i: Int) -> Bool {
        
        if let user = authModel.current_user {
            if let videos = user.liked_videos {
                return videos.contains(where: { $0 == getVideo(i: i, in: activeChannel).title })

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
                        await authModel.removeLikeFrom(getVideo(i: i, in: activeChannel))
                    }
                } else {
                    Task {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        await authModel.addLikeTo(getVideo(i: i, in: activeChannel))
                    }
                }
            }
        }
    }
    
    private func attachObservers(to player: AVPlayer) {
//        DispatchQueue.global(qos: .userInitiated).async {
        if channel == activeChannel {
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
            
            stalledObserverToken = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemPlaybackStalled,
                object: player.currentItem,
                queue: .main
            ) { _ in
                if recent_change {
                    isPlaying = true
                } else {
                    isPlaying = false
                }
                recent_change = false
            }
            
            endObserverToken = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { _ in
                recent_change = true
                
                videoCompleted(for: getVideo(i: current_playing, in: activeChannel), with: authModel.user, profile: authModel.current_user)
                player.seek(to: CMTime.zero)
                
                pause()
                shouldSkip = false
                
                trackAVStatus(for: getVideo(i: current_playing, in: activeChannel))
                nextVideo()
                
            }
        }
//        }
    }
    
    private func removeObservers(from player: AVPlayer) {
        DispatchQueue.global(qos: .userInitiated).async {
            
//            if timedPlayer != nil {
//                if let timeObserverToken = timeObserverToken {
//                    self.timedPlayer?.removeTimeObserver(timeObserverToken)
//                    self.timeObserverToken = nil
//                    self.timedPlayer = nil
//                }
//            }
            print("removed observer to \(player.currentItem)")

            
            if let endObserverToken = endObserverToken {
                NotificationCenter.default.removeObserver(endObserverToken)
                self.endObserverToken = nil
            }
            
            if let stalledObserverToken = stalledObserverToken {
                NotificationCenter.default.removeObserver(stalledObserverToken)
                self.stalledObserverToken = nil
            }
        }
    }
    
    private func previousPlayerFromChannel() -> AVPlayer? {
        return viewModel.playerManager?.getPlayer(for: getVideo(i: previous_playing, in: activeChannel))
    }
    
    private func previousPlayerAcrossChannel() -> AVPlayer? {
        return viewModel.playerManager?.getPlayer(for: getVideo(i: current_playing, in: previous_channel))
    }
    
    private func currentPlayer() -> AVPlayer? {
        return viewModel.playerManager?.getPlayer(for: getVideo(i: current_playing, in: activeChannel))
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
                            viewModel.playerManager?.playCurrentVideo()
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
}

