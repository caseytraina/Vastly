//
//  DeletedCode.swift
//  Vastly
//
//  Created by Casey Traina on 5/20/23.
//

import Foundation

//class VideoPlayerManager: ObservableObject {
//    @Published var players: [UUID: AVPlayer] = [:]
//    @Published var loadingStates: [UUID: Bool] = [:]
//    @Published var current_index: Int? {
//        didSet {
//            print("HERE: \(current_index)")
//        }
//    }
//    @Published private var channel_videos: [Video] // I'm assuming you have this property
//
//    private var videos = [Channel: [Video]]
//    
//    @Published var activeChannel: Channel = Channel.allCases[0] {
//        didSet {
//            channel_videos = videos[activeChannel]
//        }
//    }
//
//    var commandCenter: MPRemoteCommandCenter?
//    
////    var channel_videos: [Video]?
//    private var timeObserver: Any?
//
//    init(videos: [Channel: [Video]]) {
//        self.videos = videos
//        updatePlayers(videos: videos)
//        channel_videos = videos[activeChannel]
//        setupCommandCenter()
//    }
//    
//    func updatePlayers(videos: [Channel: [Video]]) {
//        players = [:] // clear previous players
//        for channel in Channel.allCases {
//            if let vids = videos[channel] {
//                for video in vids {
//                    let player = AVPlayer()
//                    player.automaticallyWaitsToMinimizeStalling = false
//                    player.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
//                    players[video.id] = player
//                }
//            }
//        }
//    }
//    
//    
//    func getPlayer(for video: Video) -> AVPlayer {
//        if let player = players[video.id] {
//            if player.currentItem == nil {
//                let item = AVPlayerItem(url: video.url ?? URL(string: "www.google.com")!)
//                player.replaceCurrentItem(with: item)
//            }
//            return player
//        } else {
//            let player = AVPlayer(url: video.url ?? URL(string: "www.google.com")!)
//            players[video.id] = player
//            return player
//        }
//    }
//    
////    func pauseAllOthers(except video: Video) {
////        DispatchQueue.main.async {
////            for player in self.players {
////                if player.key != video.id {
////                    player.value.pause()
////                }
////            }
////        }
////    }
//
//    func prepareToPlay(_ video: Video) {
//        let item = AVPlayerItem(url: video.url ?? URL(string: "www.google.com")!)
//        getPlayer(for: video).replaceCurrentItem(with: item)
//    }
//
//    func stopPlaying(_ video: Video) {
//        getPlayer(for: video).replaceCurrentItem(with: nil)
//    }
//
//    func pause(for video: Video) {
//        getPlayer(for: video).pause()
////        updateNowPlayingInfo(for: video)
//    }
//
//    func play(for video: Video, at ind: Int) {
//        getPlayer(for: video).play()
//        current_index = ind  // Update the current video when a video starts playing
//        updateNowPlayingInfo(for: video)
//    }
//
//    func setupCommandCenter() {
//        let commandCenter = MPRemoteCommandCenter.shared()
//
//        // Remove all targets to ensure a clean state
//        commandCenter.skipForwardCommand.removeTarget(nil)
//        commandCenter.skipBackwardCommand.removeTarget(nil)
//        commandCenter.playCommand.removeTarget(nil)
//        commandCenter.pauseCommand.removeTarget(nil)
//        commandCenter.nextTrackCommand.removeTarget(nil)
//        commandCenter.previousTrackCommand.removeTarget(nil)
//        
//        commandCenter.playCommand.isEnabled = true
//        commandCenter.pauseCommand.isEnabled = true
//        commandCenter.skipForwardCommand.isEnabled = true
//        commandCenter.skipBackwardCommand.isEnabled = true
//        commandCenter.nextTrackCommand.isEnabled = true
//        commandCenter.previousTrackCommand.isEnabled = true
//
//        // Set up command center targets
//        commandCenter.playCommand.addTarget { [weak self] _ in
//            self?.playCurrentVideo()
//            self?.updateNowPlayingInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
//            print("ALSO HERE: \(self?.current_index)")
//            print("ALSO HERE: \(self?.getCurrentVideo()?.show)")
//            print("ALSO HERE: \(self?.activeChannel)")
//            return .success
//            
//        }
//
//        commandCenter.pauseCommand.addTarget { [weak self] _ in
//            self?.pauseCurrentVideo()
//            self?.updateNowPlayingInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
//            print("ALSO HERE: \(self?.current_index)")
//            print("ALSO HERE: \(self?.activeChannel)")
//
//            return .success
//        }
//        
////        commandCenter.stopCommand.addTarget { [weak self] _ in
////            self?.pauseCurrentVideo()
////            self?.updateNowPlayingInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
////            return .success
////        }
//        
//        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: 15)]
//        commandCenter.skipForwardCommand.addTarget { [weak self] event in
//            guard let self = self else { return .commandFailed }
//            self.skipForward()
//            self.updateNowPlayingInfo(for: self.getCurrentVideo() ?? EMPTY_VIDEO)
//            return .success
//        }
//        
//        commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: 15)]
//        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
//            guard let self = self else { return .commandFailed }
//            self.skipBackward()
//            self.updateNowPlayingInfo(for: self.getCurrentVideo() ?? EMPTY_VIDEO)
//            return .success
//        }
//        
//
//        self.commandCenter = commandCenter
//        updateNowPlayingInfo(for: getCurrentVideo() ?? EMPTY_VIDEO)
//
//    }
//
//    func updateNowPlayingInfo(for video: Video) {
//        
//        var nowPlayingInfo = [String: Any]()
//        nowPlayingInfo[MPMediaItemPropertyTitle] = video.title
//        // ... set up other now playing info as needed
//        
//        let player = self.getPlayer(for: getCurrentVideo() ?? EMPTY_VIDEO)
//        
//        nowPlayingInfo = [
//            MPMediaItemPropertyTitle : video.title,
//            MPMediaItemPropertyArtist : video.show,
//            MPMediaItemPropertyPlaybackDuration : player.currentItem?.duration.seconds ?? 45,
//            MPNowPlayingInfoPropertyElapsedPlaybackTime: NSNumber(value: player.currentTime().seconds),
//            MPNowPlayingInfoPropertyPlaybackRate : player.rate] as [String : Any]
//        
//        if let image = UIImage(named: "AlbumImage.png") {
//            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
//        }
//        
////        if let timeObserver = self.timeObserver {
////            player.removeTimeObserver(timeObserver)
////        }
//        
//        // Create new time observer
////        let interval = CMTimeMake(value: 1, timescale: 1)
////        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
////            guard let self = self else { return }
////            let elapsedTime = player.currentTime().seconds
////            print(elapsedTime)
////            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
////            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
////        }
//        
//        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
//
//        
//        
//        
//        print("This has been called for: \(video.title)")
//        
//    }
//
//    // These are placeholders, replace with your own logic to get the current video
//    func playCurrentVideo() {
//        guard let currentVideo = getCurrentVideo() else { return }
//        play(for: currentVideo, at: current_index ?? 0)
//    }
//    
////    func nextVideo() {
////        guard let currentVideo = getCurrentVideo() else { return }
////        play(for: currentVideo)
////        updateNowPlayingInfo(for: currentVideo)
////    }
//
//    func pauseCurrentVideo() {
//        guard let currentVideo = getCurrentVideo() else { return }
//        pause(for: currentVideo)
//    }
//
//    func getCurrentVideo() -> Video? {
//        print(videos)
//        if let vids = videos[activeChannel] {
//            return vids[current_index ?? 0]
//        }
//        return nil
//    }
//    
//    private func skipForward() {
//        let player = getPlayer(for: getCurrentVideo() ?? EMPTY_VIDEO)
//        let newTime = CMTimeAdd(player.currentTime(), CMTimeMake(value: 15, timescale: 1))
//        player.seek(to: newTime)
//    }
//
//    private func skipBackward() {
//        let player = getPlayer(for: getCurrentVideo() ?? EMPTY_VIDEO)
//        let newTime = CMTimeSubtract(player.currentTime(), CMTimeMake(value: 15, timescale: 1))
//        player.seek(to: newTime)
//    }
//}

















//class VideoPlayerManager: ObservableObject {
//    @Published var players: [UUID: AVPlayer] = [:]
//    @Published var loadingStates: [UUID: Bool] = [:]
//
//    init(videos: [Channel: [Video]]) {
//        updatePlayers(videos: videos)
//    }
//
//    func updatePlayers(videos: [Channel: [Video]]) {
//        players = [:] // clear previous players
//        for channel in Channel.allCases {
//            if let vids = videos[channel] {
//                for video in vids {
//                    let player = AVPlayer()
//                    player.automaticallyWaitsToMinimizeStalling = false
//                    player.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
//                    players[video.id] = player
//                }
//            }
//        }
//    }
//
//
//    func getPlayer(for video: Video) -> AVPlayer {
//        if let player = players[video.id] {
//            if player.currentItem == nil {
//                let item = AVPlayerItem(url: video.url ?? URL(string: "www.google.com")!)
//                player.replaceCurrentItem(with: item)
//            }
//            return player
//        } else {
//            let player = AVPlayer(url: video.url ?? URL(string: "www.google.com")!)
//            players[video.id] = player
//            return player
//        }
//    }
//
////    func pauseAllOthers(except video: Video) {
////        DispatchQueue.main.async {
////            for player in self.players {
////                if player.key != video.id {
////                    player.value.pause()
////                }
////            }
////        }
////    }
//
//    func prepareToPlay(_ video: Video) {
//        let item = AVPlayerItem(url: video.url ?? URL(string: "www.google.com")!)
//        getPlayer(for: video).replaceCurrentItem(with: item)
//    }
//
//    func stopPlaying(_ video: Video) {
//        getPlayer(for: video).replaceCurrentItem(with: nil)
//    }
//
//    func pause(for video: Video) {
//        getPlayer(for: video).pause()
//    }
//
//    func play(for video: Video) {
//        getPlayer(for: video).play()
//    }
//}




//
//
//
//
//
//
//struct VideoHView: View {
//
////    @EnvironmentObject var playerManager: VideoPlayerManager
//    @EnvironmentObject var viewModel: VideoViewModel
//
//    var videos: [Channel : [Video]]
//    var channel: Channel
//
//    @Binding var current_playing: Int
//    @Binding var activeChannel: Channel
//    @Binding var isPlaying: Bool
//
////    @State var player = AVQueuePlayer()
//    @State var bioExpanded = false
//
//    @State var autoplayed = 0
//
//    @State var shouldSkip = true
//    @State var previous_playing = 0
//
//    @State private var cancellables = Set<AnyCancellable>()
//    @State private var statusObserver: AnyCancellable?
//
//    @State var recent_change = false
//
//    @State var startTime = Date()
//    @State var endTime = Date()
//
//    @State var isLoaded = false
//    @State private var timeObserverToken: Any?
//
//    var body: some View {
//
//        GeometryReader { geo in
//            // VIDEO SCROLL VIEW
//            VStack {
//                if let vids = videos[channel] {
//                    HStack(alignment: .center, spacing: 0) {
//                        ForEach(vids.indices) { i in
//                            VStack(alignment: .leading) {
//                                Group {
//                                    // EPISODE + SHOW TITLE
//                                    MyText(text: getInfo(field: .show, i: i), size: geo.size.width * 0.05, bold: true, alignment: .leading, color: .white)
//                                        .truncationMode(.tail)
//                                        .lineLimit(2)
//                                        .frame(alignment: .leading)
//
//                                    MyText(text: getInfo(field: .title, i: i), size: geo.size.width * 0.04, bold: false, alignment: .leading, color: .gray)
//                                        .truncationMode(.tail)
//                                        .lineLimit(2)
//                                }
//
//                                if abs(i - current_playing) <= 1 {
//                                    if let manager = viewModel.playerManager {
//                                        if isLoaded {
//                                            FullscreenVideoPlayer(player: manager.getPlayer(for: vids[i]))
//                                                .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
//                                                .padding(0)
//                                        } else {
//                                            VideoLoadingView()
//                                        }
//                                    }
//                                } else {
//                                    VideoLoadingView()
//                                }
//
//                                MyText(text: getInfo(field: .bio, i: i), size: geo.size.width * 0.04, bold: false, alignment: .leading, color: .gray)
//                                    .truncationMode(.tail)
//                                    .lineLimit(bioExpanded ? 10 : 3)
//                                    .padding(.bottom, geo.size.height * 0.05)
//                                    .onTapGesture {
//                                        withAnimation {
//                                            bioExpanded.toggle()
//
//                                        }
//                                    }
//                            }
//                        }
//                    }
//                    .onDisappear {
//                        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemPlaybackStalled, object: viewModel.playerManager?.getPlayer(for: videos[channel]![current_playing]).currentItem)
//                        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: viewModel.playerManager?.getPlayer(for: videos[channel]![current_playing]).currentItem)
//
//                        // Remove other observers if needed
//                    }
//                    .onAppear {
//
//                        if channel == activeChannel {
//                            if isPlaying {
//                                play(in: activeChannel)
//                            }
//                            trackAVStatus(for: getVideo(i: current_playing, in: activeChannel))
//
//                            startTime = Date()
//
//                            viewModel.playerManager?.current_index = current_playing
//                            viewModel.playerManager?.getPlayer(for: getVideo(i: current_playing, in: activeChannel))
//                                .publisher(for: \.rate)
//                                .sink { newRate in
//                                    if newRate == 0 && !recent_change {
//                                        isPlaying = false
//                                    } else {
//                                        isPlaying = true
//                                    }
//                                    recent_change = false
//                                }
//                                .store(in: &cancellables)
//
//                            NotificationCenter.default.addObserver(
//                                forName: .AVPlayerItemPlaybackStalled,
//                                object: viewModel.playerManager?.getPlayer(for: videos[channel]![current_playing]).currentItem,
//                                queue: .main
//                            ) { _ in
//                                isPlaying = false
//                            }
//
//                            NotificationCenter.default.addObserver(
//                                forName: .AVPlayerItemDidPlayToEndTime,
//                                object: viewModel.playerManager?.getPlayer(for: videos[channel]![current_playing]).currentItem,
//                                queue: .main
//                            ) { _ in
//                                videoCompleted(for: getVideo(i: current_playing, in: activeChannel))
//                                //                            recent_change = true
//                                viewModel.playerManager?.getPlayer(for: getVideo(i: current_playing, in: activeChannel)).seek(to: CMTime.zero)
//                                pause()
//                                shouldSkip = false
//                                trackAVStatus(for: getVideo(i: current_playing, in: activeChannel))
//                                nextVideo()
//                            }
//                            //                        DispatchQueue.global(qos: .userInitiated).async {
//
//                            //                        }
//
//                            videoWatched(for: getVideo(i: current_playing, in: activeChannel))
//                            channelTapped(for: activeChannel)
//                        }
//                    }
//                    .modifier(ScrollingHStackModifier(items: vids.count, itemWidth: VIDEO_WIDTH, itemSpacing: 0, current: $current_playing))
//                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
//                        if channel == activeChannel {
//                            viewModel.playerManager?.updateNowPlayingInfo(for: getVideo(i: current_playing, in: activeChannel))
//                        }
//                    }
//                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.protectedDataWillBecomeUnavailableNotification)) { _ in
//                        // The device is about to be locked
//                        if channel == activeChannel {
//                            viewModel.playerManager?.updateNowPlayingInfo(for: getVideo(i: current_playing, in: activeChannel))
//                        }
//                    }
//                    .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { notification in
//                        if channel == activeChannel {
//                            handleInterruption(notification: notification)
//                        }
//                    }
//                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
//                    .onChange(of: current_playing) { newIndex in
//                        if channel == activeChannel {
//                            print(newIndex)
//                            endTime = Date()
//                            logWatchTime(from: startTime, to: endTime, for: getVideo(i: previous_playing, in: activeChannel), time: (viewModel.playerManager?.getPlayer(for: getVideo(i: previous_playing, in: activeChannel)).currentItem!.duration.seconds) ?? 0.0)
//                            viewModel.playerManager?.current_index = newIndex
//
//                            recent_change = true
//                            viewModel.playerManager?.pause(for: getVideo(i: previous_playing, in: activeChannel))
//                            trackAVStatus(for: getVideo(i: newIndex, in: activeChannel))
//
//                            if isPlaying {
//                                viewModel.playerManager?.play(for: getVideo(i: newIndex, in: activeChannel), at: newIndex)
//                            }
//                            startTime = Date()
//
//                            previous_playing = newIndex
//                            videoWatched(for: getVideo(i: newIndex, in: activeChannel))
//                            recent_change = false
//                            viewModel.playerManager?.updateNowPlayingInfo(for: getVideo(i: newIndex, in: activeChannel))
//
//                        }
//
//                    }
//                    .onChange(of: activeChannel) { newChannel in
//                        if newChannel == channel {
//                            viewModel.playerManager?.current_index = current_playing
//                            viewModel.playerManager?.activeChannel = newChannel
//                            viewModel.playerManager?.updateNowPlayingInfo(for: getVideo(i: current_playing, in: newChannel))
//                        }
//                        endTime = Date()
//
//                        logWatchTime(from: startTime, to: endTime, for: getVideo(i: current_playing, in: activeChannel), time: (viewModel.playerManager?.getPlayer(for: getVideo(i: current_playing, in: activeChannel)).currentItem!.duration.seconds) ?? 0.0)
//
//                        recent_change = true
//                        pause()
//
//                        startTime = Date()
//                        channelTapped(for: newChannel)
//
//                        trackAVStatus(for: getVideo(i: current_playing, in: newChannel))
//
//                        if newChannel == channel && isPlaying {
//                            play(in: newChannel)
//                        }
//                        recent_change = false
//
//                    }
//                    .frame(width:  VIDEO_WIDTH)
//                    .onChange(of: isPlaying) { newPlaying in
//
//                        if newPlaying {
//                            if channel == activeChannel {
//                                play(in: activeChannel)
//                            }
//                        } else {
//                            if channel == activeChannel {
//                                pause()
//                            }
//                        }
//
//                    }
//                }
//
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
//        }
//    }
//    enum Field {
//        case channel, title, bio, show
//    }
//
//    private func getVideo(i: Int, in channel: Channel) -> Video {
//        if let vids = videos[channel] {
//            let video = vids[i]
//            return video
//        } else {
//            return EMPTY_VIDEO
//        }
//    }
//
//    private func getInfo(field: Field, i: Int) -> String {
//        if let channelVideos = videos[activeChannel], i < channelVideos.count {
//            let video = channelVideos[i]
//            switch field {
//            case .channel:
//                return video.channel
//            case .title:
//                return video.title
//            case .show:
//                return video.show
//            case .bio:
//                return video.bio
//            }
//        }
//        return "No data for \(activeChannel) Channel"
//    }
//    private func initCommandCenter() {
////        let command = MPRemoteCommandCenter.shared()
////
////        command.skipForwardCommand.isEnabled = false
////        command.skipBackwardCommand.isEnabled = false
////
////        command.nextTrackCommand.isEnabled = true
////        command.previousTrackCommand.isEnabled = true
////        command.playCommand.isEnabled = true
////        command.pauseCommand.isEnabled = true
////        command.stopCommand.isEnabled = true
////
////
////        command.playCommand.addTarget { [self] event in
////            if channel == activeChannel {
//////                self.player.play()
////                viewModel.playerManager?.play(for: getVideo(i: current_playing, in: activeChannel))
////                isPlaying = true
////                if let vids = videos[activeChannel] {
////                    setInfo(video: vids[current_playing])
////                }
////            }
////            return .success
////        }
////
//////        command.skipForwardCommand.addTarget { [self] (event) -> MPRemoteCommandHandlerStatus in
//////            if let event = event as? MPSkipIntervalCommandEvent {
//////                self.skip(seconds: event.interval, direction: .forward)
//////                return .success
//////            }
//////            return .commandFailed
//////        }
//////
//////        command.skipBackwardCommand.addTarget { [self] (event) -> MPRemoteCommandHandlerStatus in
//////            if let event = event as? MPSkipIntervalCommandEvent {
//////                self.skip(seconds: event.interval, direction: .backward)
//////                return .success
//////            }
//////            return .commandFailed
//////        }
////
////        command.nextTrackCommand.addTarget { [self] event in
////            nextVideo()
////            return .success
////        }
////
////        command.previousTrackCommand.addTarget { [self] event in
////            previousVideo()
////            return .success
////        }
////
////        command.pauseCommand.addTarget { [self] event in
////            if channel == activeChannel {
//////                self.player.pause()
////                viewModel.playerManager?.pause(for: getVideo(i: current_playing, in: activeChannel))
////                isPlaying = false
////                if let vids = videos[activeChannel] {
////                    setInfo(video: vids[current_playing])
////                }
////            }
////            return .success
////        }
////
////        let commandCenter = MPRemoteCommandCenter.shared()
////
////        let player = viewModel.playerManager?.getPlayer(for: getVideo(i: current_playing, in: activeChannel))
////
////
////        // Add handler for Play Command
////        commandCenter.playCommand.addTarget { [unowned self] event in
////            if player?.rate == 1.0 {
////                player?.play()
////                return .success
////            }
////            return .commandFailed
////        }
////
////        // Add handler for Pause Command
////        commandCenter.pauseCommand.addTarget { [unowned self] event in
////            if player?.rate == 1.0 {
////                player?.pause()
////                return .success
////            }
////            return .commandFailed
////        }
////
////
////
//    }
//
//    private func setInfo(video: Video) {
////
////        let player = viewModel.playerManager?.getPlayer(for: (videos[channel]![current_playing]))
////
////        var nowPlayingInfo = [
////            MPMediaItemPropertyTitle : video.title,
////            MPMediaItemPropertyArtist : video.show,
////            MPMediaItemPropertyAlbumTitle : "Vastly",
////            MPMediaItemPropertyPlaybackDuration : player?.currentItem?.duration,
////            MPNowPlayingInfoPropertyElapsedPlaybackTime: player?.currentTime().seconds,
////            MPNowPlayingInfoPropertyPlaybackRate : player?.rate] as [String : Any]
////
////
////        if let image = UIImage(named: "AlbumImage.png") {
////            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
////        }
////
////        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
////
//    }
//
//    enum SeekDirection {
//        case forward
//        case backward
//    }
//
//    private func skip(seconds: Double, direction: SeekDirection) {
//
//        let skip = direction == .forward ? seconds : seconds * -1
//
//        let player = viewModel.playerManager?.getPlayer(for: getVideo(i: current_playing, in: activeChannel))
//
//        guard let duration  = player?.currentItem?.duration else {
//            return
//        }
//
//        let playerCurrentTime = CMTimeGetSeconds(player?.currentTime() ?? CMTime.zero)
//        let newTime = playerCurrentTime + skip
//        if newTime < (CMTimeGetSeconds(duration)) {
//            let time2: CMTime = CMTimeMake(value: Int64(newTime*1000), timescale: 1000)
//            player?.seek(to: time2, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
//        }
//    }
//
//    private func handleInterruption(notification: Notification) {
//        guard let info = notification.userInfo,
//              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
//              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
//            return
//        }
//
//        switch type {
//        case .began:
//            // Interruption began, take appropriate actions (e.g. save state, update user interface)
//            pause()
//        case .ended:
//            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
//                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
//                if options.contains(.shouldResume) {
//                    // Interruption ended, and the system suggests that you should resume audio
//                    // Here you can resume your audio and refresh your metadata
//                    if let vids = videos[activeChannel] {
//                        setInfo(video: vids[current_playing])
//                    }
//                    play(in: activeChannel)
//                }
//            }
//        default:
//            play(in: activeChannel)
//        }
//    }
//
//
//    private func play(in channel: Channel) {
//        if channel == activeChannel {
//            viewModel.playerManager?.play(for: getVideo(i: current_playing, in: channel), at: current_playing)
//        }
//    }
//
//    private func pause() {
//        viewModel.playerManager?.pause(for: getVideo(i: current_playing, in: channel))
//    }
//
//    private func nextVideo() {
//        current_playing += 1;
//        if let vids = videos[activeChannel] {
//            setInfo(video: vids[current_playing])
//        }
//        isPlaying = true
//    }
//
//    private func previousVideo() {
//        current_playing -= 1;
//        if let vids = videos[activeChannel] {
//            setInfo(video: vids[current_playing])
//        }
//    }
//
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
//                            isLoaded = false
//                        case .readyToPlay:
//                            isLoaded = true
//                            isPlaying = true
//                            if channel == activeChannel {
//                                viewModel.playerManager?.updateNowPlayingInfo(for: getVideo(i: current_playing, in: activeChannel))
//                            }
//                        case .failed:
//                            // Handle failed status
//                            isLoaded = false
//                        @unknown default:
//                            // Handle other unknown cases
//                            isLoaded = false
//                        }
//                    })!
//            )
//        }
//    }
//}


















/*
 
 class VideoPlayerManager: ObservableObject {
     @Published var players: [UUID: AVPlayer] = [:]
     @Published var loadingStates: [UUID: Bool] = [:]
 //    @Published var current_index: Int?
     
     @State var video_indices = [Int](repeating: 0, count: Channel.allCases.count)
     @State var channel_index = 0
     
     @Published var videos: [Channel: [Video]]
     
 //    var activeChannel: Channel = Channel.allCases[0]
     
     var commandCenter: MPRemoteCommandCenter?
     
 //    var channel_videos: [Video]?
     
     init(videos: [Channel: [Video]]) {
         self.videos = videos
         updatePlayers(videos: videos)
 //        channel_videos = videos[activeChannel()]
         setupCommandCenter()
     }
     
     func updatePlayers(videos: [Channel: [Video]]) {
         players = [:] // clear previous players
         for channel in Channel.allCases {
             if let vids = videos[channel] {
                 for video in vids {
                     let player = AVPlayer()
                     player.automaticallyWaitsToMinimizeStalling = false
                     player.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
                     players[video.id] = player
                 }
             }
         }
     }
     
     
     func getPlayer(for video: Video) -> AVPlayer {
         if let player = players[video.id] {
             if player.currentItem == nil {
                 let item = AVPlayerItem(url: video.url ?? URL(string: "www.google.com")!)
                 player.replaceCurrentItem(with: item)
             }
             return player
         } else {
             let player = AVPlayer(url: video.url ?? URL(string: "www.google.com")!)
             players[video.id] = player
             return player
         }
     }
     
 //    func pauseAllOthers(except video: Video) {
 //        DispatchQueue.main.async {
 //            for player in self.players {
 //                if player.key != video.id {
 //                    player.value.pause()
 //                }
 //            }
 //        }
 //    }

     func prepareToPlay(_ video: Video) {
         let item = AVPlayerItem(url: video.url ?? URL(string: "www.google.com")!)
         getPlayer(for: video).replaceCurrentItem(with: item)
     }

     func stopPlaying(_ video: Video) {
         getPlayer(for: video).replaceCurrentItem(with: nil)
     }

     func pause(for video: Video) {
         getPlayer(for: video).pause()
     }

     func play(for video: Video) {
         getPlayer(for: video).play()
     }
     
     func nextVideoInChannel() {
         if video_indices[channel_index] + 1 < videos[activeChannel()]?.count ?? 0 {
             pauseCurrentVideo()
             video_indices[channel_index] += 1
             playCurrentVideo()
             updateNowPlayingInfo(for: getCurrentVideo() ?? EMPTY_VIDEO)
         }
     }
     
     func previousVideoInChannel() {
         if video_indices[channel_index] > 0 {
             pauseCurrentVideo()
             video_indices[channel_index] -= 1
             playCurrentVideo()
             updateNowPlayingInfo(for: getCurrentVideo() ?? EMPTY_VIDEO)
         }
     }
     
     func changeToChannel(to channel: Channel) {
         pauseCurrentVideo()
         channel_index = Channel.allCases.firstIndex(of: channel) ?? 0
         playCurrentVideo()
         updateNowPlayingInfo(for: getCurrentVideo() ?? EMPTY_VIDEO)
     }

     func setupCommandCenter() {
         let commandCenter = MPRemoteCommandCenter.shared()

         // Remove all targets to ensure a clean state
         commandCenter.skipForwardCommand.removeTarget(nil)
         commandCenter.skipBackwardCommand.removeTarget(nil)
         commandCenter.playCommand.removeTarget(nil)
         commandCenter.pauseCommand.removeTarget(nil)
         commandCenter.nextTrackCommand.removeTarget(nil)
         commandCenter.previousTrackCommand.removeTarget(nil)
         
         commandCenter.playCommand.isEnabled = true
         commandCenter.pauseCommand.isEnabled = true
         commandCenter.skipForwardCommand.isEnabled = true
         commandCenter.skipBackwardCommand.isEnabled = true
         commandCenter.nextTrackCommand.isEnabled = true
         commandCenter.previousTrackCommand.isEnabled = true

         // Set up command center targets
         commandCenter.playCommand.addTarget { [weak self] _ in
             self?.playCurrentVideo()
             self?.updateNowPlayingInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
             return .success
         }

         commandCenter.pauseCommand.addTarget { [weak self] _ in
             self?.pauseCurrentVideo()
             self?.updateNowPlayingInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
             return .success
         }

         self.commandCenter = commandCenter
     }

     func updateNowPlayingInfo(for video: Video) {
         var nowPlayingInfo = [String: Any]()
         nowPlayingInfo[MPMediaItemPropertyTitle] = video.title
         // ... set up other now playing info as needed
         
         let player = self.getPlayer(for: getCurrentVideo() ?? EMPTY_VIDEO)
         
         nowPlayingInfo = [
             MPMediaItemPropertyTitle : video.title,
             MPMediaItemPropertyArtist : video.show,
             MPMediaItemPropertyAlbumTitle : "Vastly",
             MPMediaItemPropertyPlaybackDuration : NSNumber(value: player.currentItem?.duration.seconds ?? 0.0),
             MPNowPlayingInfoPropertyElapsedPlaybackTime: NSNumber(value: player.currentTime().seconds),
             MPNowPlayingInfoPropertyPlaybackRate : player.rate] as [String : Any]

         
         if let image = UIImage(named: "AlbumImage.png") {
             nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
         }
         MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
     }

     // These are placeholders, replace with your own logic to get the current video
     func playCurrentVideo() {
         guard let currentVideo = getCurrentVideo() else { return }
         play(for: currentVideo)
     }

     func pauseCurrentVideo() {
         guard let currentVideo = getCurrentVideo() else { return }
         pause(for: currentVideo)
     }

     func getCurrentVideo() -> Video? {
         
         if let vids = videos[activeChannel()] {
             return vids[video_indices[channel_index]]
         }

         return nil
     }
     
     func activeChannel() -> Channel {
         return Channel.allCases[channel_index]
     }
 }

 */
