//
//  CatalogPlayerManager.swift
//  Vastly
//
//  Created by Michael Murray on 10/20/23
//

import Foundation
import AVKit
import SwiftUI
import MediaPlayer
import Combine

/*
 This View Model governs all AVPlayers and their states, and controls the starting and stopping of videos. This exists as a child of the CatalogModel.
 */

enum VideoStatus {
    case loading
    case ready
    case unknown
    case failed
}

class CatalogPlayerManager: ObservableObject {
    
    var onChange: (() -> Void)?
    
    @Published var players: [String: AVQueuePlayer] = [:]
    
    var videoStatuses: [String : VideoStatus] = [:] {
        didSet {
            onChange?()
        }
    }
    
    @Published var timeObserverToken: Any?
    @Published var endObserverToken: Any?
    
    var videoCancellables: [String : AnyCancellable] = [:]
    
    var playerTimes: [String : CMTime] = [:]

    
    var commandCenter: MPRemoteCommandCenter?
    @Published var catalog: Catalog 
    @Published var isInBackground = false {
        didSet {
            print("background value changed: \(self.isInBackground)")
        }
    }
    
    @Published var isVideoMode: Bool

    var defaultRegisteredCommands: [NowPlayableCommand] {
        return [.togglePausePlay,
                .play,
                .pause,
                .nextTrack,
                .previousTrack,
                .changePlaybackPosition
                
        ]
    }
    
    var defaultDisabledCommands: [NowPlayableCommand] {
        return [.skipBackward,
                .skipForward,
                .changePlaybackRate,
                .enableLanguageOption,
                .disableLanguageOption]
    }

    init(_ catalog: Catalog, isVideoMode: Published<Bool>) {
        print("INIT: Catalog Player Manager")
        self.catalog = catalog
        self._isVideoMode = isVideoMode
        setupCommandCenter()
//        do {
//            try handleNowPlayableConfiguration(commands: self.defaultDisabledCommands,
//                                               disabledCommands: self.defaultDisabledCommands,
//                                               commandHandler: handleCommand(command:event:),
//                                               interruptionHandler: handleInterrupt(with:))
//        } catch {
//            print("**** There was an issue configuring commands: \(error)")
//        }
    }
    
    // This function returns the AVPlayer for a video on the fly

    func getPlayer(for video: Video) -> AVQueuePlayer {
        if let player = players[video.id] {
            
//            if isInBackground && player.items().count == 1 {
//                if let url = URL(string: TTS_IMAGEKIT_ENDPOINT + video.id + ".mp3") {
//                    let intro = AVPlayerItem(url: url)
//                    player.insert(intro, after: nil)
//                }
//            }
            
            if player.currentItem == nil {
                let vid = AVPlayerItem(url: video.url ?? URL(string: "www.google.com")!)
                player.insert(vid, after: nil)
//                player.replaceCurrentItem(with: vid)

                if let url = URL(string: TTS_IMAGEKIT_ENDPOINT + video.id + ".mp3") {
                    let intro = AVPlayerItem(url: url)
                    player.insert(intro, after: nil)
                }

                players[video.id] = player
            }

            return player
        } else {
            var items: [AVPlayerItem] = []

            if let url = URL(string: TTS_IMAGEKIT_ENDPOINT + video.id + ".mp3") {
                let intro = AVPlayerItem(url: url)
                items.append(intro)
            }
            
            let vid = AVPlayerItem(url: video.url ?? URL(string: "www.google.com")!)
            items.append(vid)
            
            let player = AVQueuePlayer(items: items)
            
            players[video.id] = player
            return player
        }
    }
    
    func getStatus(for video: Video) -> VideoStatus {
        if let status = self.videoStatuses[video.id] {
            return status
        }
        return .loading
    }
    
    func updateBackgroundState(isInBackground: Bool) {
        self.isInBackground = isInBackground
    }
    
    // pauses the video.
    func pause(for video: Video) {
        getPlayer(for: video).pause()
    }
    
    func getDurationOfVideo(video: Video) -> CMTime {
        let player = self.getPlayer(for: video)
        return player.currentItem?.duration ?? CMTime(value: 0, timescale: 1000)
    }
    
    // plays the video.
    func play(for video: Video) {
        
        let queuePlayer = getPlayer(for: video)
        if !isInBackground {
            if queuePlayer.currentItem != queuePlayer.items().last {
                queuePlayer.advanceToNextItem()
            }
        }
        self.observeStatus(video: video, player: queuePlayer)
        self.observePlayer(video: video, to: queuePlayer)
        self.updateNowPlayingInfo(for: video)
        queuePlayer.play()
    }

    func handleNowPlayableConfiguration(commands: [NowPlayableCommand],
                                        disabledCommands: [NowPlayableCommand],
                                        commandHandler: @escaping (NowPlayableCommand, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus,
                                        interruptionHandler: @escaping (NowPlayableInterruption) -> Void) throws {
        
        // Remember the interruption handler.
//        self.interruptionHandler = interruptionHandler
        
        // Use the default behavior for registering commands.
        try configureRemoteCommands(commands, disabledCommands: disabledCommands, commandHandler: commandHandler)
    }
    
    func configureRemoteCommands(_ commands: [NowPlayableCommand],
                                 disabledCommands: [NowPlayableCommand],
                                 commandHandler: @escaping (NowPlayableCommand, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus) throws {
        
        // Check that at least one command is being handled.
        guard commands.count > 1 else { throw NowPlayableError.noRegisteredCommands }
        
        // Configure each command.
        for command in NowPlayableCommand.allCases {
            print("**** Init command: \(command)")
            // Remove any existing handler.
            command.removeHandler()
            
            // Add a handler if necessary.
            if commands.contains(command) {
                command.addHandler(commandHandler)
            }
            
            // Disable the command if necessary.
            command.setDisabled(disabledCommands.contains(command))
        }
    }
    
    // Handle a command registered with the Remote Command Center.
    private func handleCommand(command: NowPlayableCommand, event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        
        switch command {
            
        case .pause:
            self.pauseCurrentVideo()
            
        case .play:
            self.playCurrentVideo()
            
        case .stop:
            self.pauseCurrentVideo()
            
        case .togglePausePlay:

            self.pauseCurrentVideo()
            
        case .nextTrack:
            self.pauseCurrentVideo()
            self.catalog.nextVideo()
            self.playCurrentVideo()
            
        case .previousTrack:
            self.pauseCurrentVideo()
            self.seekTo(time: CMTime(value: 0, timescale: 0))
            self.catalog.previousVideo()
            self.playCurrentVideo()
            
//        case .changePlaybackRate:
//            guard let event = event as? MPChangePlaybackRateCommandEvent else { return .commandFailed }
//            setPlaybackRate(event.playbackRate)
            
//        case .seekBackward:
//            guard let event = event as? MPSeekCommandEvent else { return .commandFailed }
//            setPlaybackRate(event.type == .beginSeeking ? -3.0 : 1.0)
//            
//        case .seekForward:
//            guard let event = event as? MPSeekCommandEvent else { return .commandFailed }
//            setPlaybackRate(event.type == .beginSeeking ? 3.0 : 1.0)
            
        case .skipBackward:
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            self.seekForward(by: 15)

        case .skipForward:
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            self.seekForward(by: 15)
            
        case .changePlaybackPosition:
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self.seekTo(time: CMTime(seconds: event.positionTime, preferredTimescale: 1))
            
//        case .enableLanguageOption:
//            guard let event = event as? MPChangeLanguageOptionCommandEvent else { return .commandFailed }
//            guard didEnableLanguageOption(event.languageOption) else { return .noActionableNowPlayingItem }

//        case .disableLanguageOption:
//            guard let event = event as? MPChangeLanguageOptionCommandEvent else { return .commandFailed }
//            guard didDisableLanguageOption(event.languageOption) else { return .noActionableNowPlayingItem }

        default:
            break
        }
        
        return .success
    }
    
    // Handle a session interruption.
    
    private func handleInterrupt(with interruption: NowPlayableInterruption) {
        
        
    }
    
    enum NowPlayableInterruption {
        case began, ended(Bool), failed(Error)
    }

    
    // this function initializes the physical command center controls.
    func setupCommandCenter() {
        print("**** Setup Command Center")
//        DispatchQueue.main.async {
            UIApplication.shared.beginReceivingRemoteControlEvents()
//        }

        let commandCenter = MPRemoteCommandCenter.shared()

        // Remove all targets to ensure a clean state
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)

        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true

        // Set up command center targets
        commandCenter.playCommand.addTarget { [self] _ in
            self.playCurrentVideo()
            self.updateNowPlayingInfo(for: self.getCurrentVideo() ?? EMPTY_VIDEO)
            print("**** Successful Lockscreen action: Play")
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [self] _ in
            self.pauseCurrentVideo()
            self.updateNowPlayingInfo(for: self.getCurrentVideo() ?? EMPTY_VIDEO)
            print("**** Successful Lockscreen action: Pause")
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [self] (event) -> MPRemoteCommandHandlerStatus in
            let player = self.getPlayer(for: self.getCurrentVideo() ?? EMPTY_VIDEO)
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                player.seek(to: CMTime(seconds: event.positionTime, preferredTimescale: 1))
                self.updateNowPlayingInfo(for: self.getCurrentVideo() ?? EMPTY_VIDEO)
                print("**** Successful Lockscreen action: Scrub")
                return .success
            }
            print("**** Unsuccessful Lockscreen action: Scrub")
            return .commandFailed
        }
        
        commandCenter.nextTrackCommand.addTarget { [self] _ in
            self.catalog.nextVideo()
//            self?.updateStaticInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
            self.updateNowPlayingInfo(for: self.getCurrentVideo() ?? EMPTY_VIDEO)
            print("**** Successful Lockscreen action: Next")
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [self] _ in
            self.catalog.previousVideo()
//            self?.updateStaticInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
            self.updateNowPlayingInfo(for: self.getCurrentVideo() ?? EMPTY_VIDEO)
            print("**** Successful Lockscreen action: Previous")
            return .success
        }
        self.commandCenter = commandCenter
    }
    
    // Function to update static metadata
    func updateStaticInfo(for video: Video) {
        
        var staticInfo = [String: Any]()
        staticInfo[MPMediaItemPropertyTitle] = video.title
        staticInfo[MPMediaItemPropertyAssetURL] = video.url!
        staticInfo[MPMediaItemPropertyMediaType] = NSNumber(value: MPMediaType.anyVideo.rawValue)
        staticInfo[MPMediaItemPropertyAlbumArtist] = video.author.name
        staticInfo[MPMediaItemPropertyArtist] = video.author.name
        staticInfo[MPMediaItemPropertyAlbumTitle] = "Vastly"
        MPNowPlayingInfoCenter.default().nowPlayingInfo = staticInfo
        getPlayer(for: video).items().last?.nowPlayingInfo = staticInfo
        
        URLSession.shared.dataTask(with: video.author.fileName ?? EMPTY_AUTHOR.fileName!) { [self] (data, response, error) in
            guard let data = data, error == nil else {
                print("**** Error downloading image: \(error?.localizedDescription ?? "No error description available")")
                return
            }
            
            if let image = UIImage(data: data) {
                staticInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                MPNowPlayingInfoCenter.default().nowPlayingInfo = staticInfo
                self.getPlayer(for: video).items().last?.nowPlayingInfo = staticInfo

                // Update MPNowPlayingInfoCenter
                print("**** Successfully updated Metadata")
            }
        }.resume()
    }
    
    
    // this function updates the command center metadata that is displayed. It must be called any time a change is made to the video or its state.
    // TODO: This should be made private, SearchVideoView uses it currently
    func updateNowPlayingInfo(for video: Video) {
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
        
        let player = self.getPlayer(for: video)
        
        
        if let item = player.currentItem {
            NSLog("%@", "**** Set playback info: rate \(player.rate), position \(player.currentTime().asString), duration \(player.currentItem?.duration)")

            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = item.duration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = item.currentTime().seconds
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
            nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0

            nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
            self.getPlayer(for: video).items().last?.nowPlayingInfo = nowPlayingInfo

        }
    }
    
    // This function pauses the current video.
    func pauseCurrentVideo() {
        guard let currentVideo = getCurrentVideo() else { return }
        pause(for: currentVideo)
    }
    
    // This function plays the current video.
    func playCurrentVideo() {
        guard let currentVideo = getCurrentVideo() else { return }
        play(for: currentVideo)
    }
    

    // This function returns the current video.
    private func getCurrentVideo() -> Video? {
        return self.catalog.currentVideo
    }

    // This function plays the next video in the currently active channel.
    // This is only used in the command center buttons, it shouldn't be used pubically
    private func nextVideo() {
        pauseCurrentVideo()
        if let _ = self.catalog.nextVideo() {
            playCurrentVideo()
        }
    }

    // This function plays the previous video in the currently active channel.
    // This is only used in the command center buttons, it shouldn't be used pubically
    private func previousVideo() {
        pauseCurrentVideo()
        if let _ = self.catalog.previousVideo() {
            playCurrentVideo()
        }
    }
    
    // this function facilitates a change in channel
    func changeToChannel(_ channel: Channel, shouldPlay: Bool) {
//        self.updateStaticInfo(for: self.getCurrentVideo() ?? EMPTY_VIDEO)
        if shouldPlay {
            playCurrentVideo()
        }
    }
    
    func seekForward(by increment: Double) {
        if let video = self.getCurrentVideo() {
            let player = self.getPlayer(for: video)
            let currentTime = player.currentTime().seconds
            player.seek(to: CMTime(seconds: currentTime + increment, preferredTimescale: 1)) // skip forward by 15 seconds
            self.updateNowPlayingInfo(for: video)
        }
    }
    
    func seekTo(time: CMTime) {
        if let video = self.getCurrentVideo() {
            let player = self.getPlayer(for: video)
            let currentTime = player.currentTime().seconds
            player.seek(to: time) // skip forward by 15 seconds
            self.updateNowPlayingInfo(for: video)
        }
    }
    
    func seekBackward(by increment: Double) {
        if let video = self.getCurrentVideo() {
            let player = self.getPlayer(for: video)
            let currentTime = player.currentTime().seconds
            player.seek(to: CMTime(seconds: currentTime - increment, preferredTimescale: 1)) // skip forward by 15 seconds
            self.updateNowPlayingInfo(for: video)
        }
    }
    
    private func observeStatus(video: Video, player: AVQueuePlayer) {
        self.videoCancellables[video.id]?.cancel()

//        if let player = viewModel.playerManager?.getPlayer(for: video) {
        
        self.videoCancellables[video.id] = AnyCancellable(
            (player.currentItem?
                    .publisher(for: \.status)
                    .sink { status in
                        switch status {
                        case .unknown:
                            // Handle unknown status
                            DispatchQueue.main.async {
                                self.videoStatuses[video.id] = .unknown
                            }
                            
                        case .readyToPlay:
                            
                            DispatchQueue.main.async {
                                self.videoStatuses[video.id] = .ready
                            }
                            
                            print("Status ready: \(self.videoStatuses[video.id])")

                        case .failed:
                            // Handle failed status
                            DispatchQueue.main.async {
                                self.videoStatuses[video.id] = .failed
                            }
                            print("Error video failed: \(video)")
                        @unknown default:
                            // Handle other unknown cases
                            DispatchQueue.main.async {
                                self.videoStatuses[video.id] = .loading
                            }
                            print("Status default: \(self.videoStatuses[video.id])")

                        }
                    })!
            )
    }
    
    private func observePlayer(video: Video, to player: AVQueuePlayer) {
        if let item = player.currentItem {
            if let timeObserverToken = timeObserverToken {
                NotificationCenter.default.removeObserver(timeObserverToken)
                self.timeObserverToken = nil
            }
            
            //        DispatchQueue.global(qos: .userInitiated).async {
            print("Attached observer to \(player.currentItem)")
            
            player.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                DispatchQueue.main.async {
                    let duration = item.asset.duration
                    self.playerTimes[video.id] = duration ?? CMTime(value: 0, timescale: 1000)
                    
                    self.timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1000), queue: .main) { time in
                        self.playerTimes[video.id] = time
                        self.onChange?()
                        //                            self.playerProgress = time.seconds / (duration?.seconds ?? 1.0)
                        //                            self.timedPlayer = player
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
                object: item,
                queue: .main
            ) { _ in
                if item == player.items().last {
                    self.playSound()
                    self.pauseCurrentVideo()
                    self.seekTo(time: CMTime(value: 0, timescale: 1000))
                    self.catalog.nextVideo()
                    self.playCurrentVideo()
                } else {
                    self.observeStatus(video: video, player: player)
                    self.observePlayer(video: video, to: player)
                }
            }
        }
    }
    
    private func playSound() {

        if let path = Bundle.main.path(forResource: "Blow", ofType: "aiff") {
            let soundUrl = URL(fileURLWithPath: path)
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: soundUrl)
                audioPlayer.play()
            } catch {
                print("Error initializing AVAudioPlayer.")
            }
        }
    }
        
    
    
    
}
