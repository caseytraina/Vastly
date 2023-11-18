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
    
    @Published var players: [String: AVPlayer] = [:]
    
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
//    @State private var statusObserver: AnyCancellable?

    
    init(_ catalog: Catalog, isVideoMode: Published<Bool>) {
        print("INIT: Catalog Player Manager")
        self.catalog = catalog
        self._isVideoMode = isVideoMode
//        setupCommandCenter()
    }
    
    // This function returns the AVPlayer for a video on the fly
    func getPlayer(for video: Video) -> AVPlayer {
        if let player = players[video.id] {
            if player.currentItem == nil {
                let item = AVPlayerItem(url: video.url ?? URL(string: "www.google.com")!)
                item.preferredPeakBitRate = 4000000
                item.preferredPeakBitRateForExpensiveNetworks = 3000000       
                player.replaceCurrentItem(with: item)
                self.observeStatus(video: video, player: player)
            }
            return player
        } else {
            let player = AVPlayer(url: video.url ?? URL(string: "www.google.com")!)

            players[video.id] = player
            self.observeStatus(video: video, player: player)
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
    
    func pauseAllOthers(except video: Video) {
        DispatchQueue.main.async {
            for player in self.players {
                if player.key != video.id {
                    player.value.pause()
                }
            }
        }
    }
    
    func getDurationOfVideo(video: Video) -> CMTime {
        let player = self.getPlayer(for: video)
        return player.currentItem?.duration ?? CMTime(value: 0, timescale: 1000)
    }
    
    // plays the video.
    func play(for video: Video) {
        let player = getPlayer(for: video)
        observePlayer(video: video, to: player)
        player.play()
    }

    // this function initializes the physical command center controls.
    func setupCommandCenter() {
        print("Setup Command Center")
        UIApplication.shared.beginReceivingRemoteControlEvents()

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
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true

        // Set up command center targets
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.playCurrentVideo()
            self?.updateNowPlayingInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
            print("Successful Lockscreen action: Play")
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pauseCurrentVideo()
            self?.updateNowPlayingInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
            print("Successful Lockscreen action: Pause")
            return .success
        }

        commandCenter.skipForwardCommand.addTarget { [weak self] event -> MPRemoteCommandHandlerStatus in
            if let player = self?.getPlayer(for: self?.getCurrentVideo() ?? EMPTY_VIDEO) {
                let currentTime = player.currentTime().seconds
                player.seek(to: CMTime(seconds: currentTime + 15, preferredTimescale: 1)) // skip forward by 15 seconds
                self?.updateNowPlayingInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
                print("Successful Lockscreen action: Skip 15 Forward")
                return .success
            }
            print("Unsuccessful Lockscreen action: Skip 15 Forward")
            return .commandFailed
        }

        commandCenter.skipBackwardCommand.addTarget { [weak self] event -> MPRemoteCommandHandlerStatus in
            if let player = self?.getPlayer(for: self?.getCurrentVideo() ?? EMPTY_VIDEO) {
                let currentTime = player.currentTime().seconds
                player.seek(to: CMTime(seconds: max(currentTime - 15, 0), preferredTimescale: 1)) // skip backward by 15 seconds, but don't go past the beginning of the track
                self?.updateNowPlayingInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
                print("Successful Lockscreen action: Skip 15 Back")
                return .success
            }
            print("Unsuccessful Lockscreen action: Skip 15 Back")
            return .commandFailed
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            if let player = self?.getPlayer(for: self?.getCurrentVideo() ?? EMPTY_VIDEO),
               let event = event as? MPChangePlaybackPositionCommandEvent {
                player.seek(to: CMTime(seconds: event.positionTime, preferredTimescale: 1))
                self?.updateNowPlayingInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
                print("Successful Lockscreen action: Scrub")
                return .success
            }
            print("Unsuccessful Lockscreen action: Scrub")
            return .commandFailed
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            self?.nextVideo()
            self?.updateStaticInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
            self?.updateNowPlayingInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
            print("Successful Lockscreen action: Next")
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            self?.previousVideo()
            self?.updateStaticInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
            self?.updateNowPlayingInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
            print("Successful Lockscreen action: Previous")
            return .success
        }

        self.commandCenter = commandCenter
        if let video = self.getCurrentVideo() {
            self.updateStaticInfo(for: video)
            self.updateNowPlayingInfo(for: video)
        }
    }
    
    // Function to update static metadata
    private func updateStaticInfo(for video: Video) {
        var staticInfo = [String: Any]()
        staticInfo[MPMediaItemPropertyTitle] = video.title
        staticInfo[MPMediaItemPropertyArtist] = video.author.name
        staticInfo[MPMediaItemPropertyAlbumTitle] = "Vastly"
        MPNowPlayingInfoCenter.default().nowPlayingInfo = staticInfo

        URLSession.shared.dataTask(with: video.author.fileName ?? EMPTY_AUTHOR.fileName!) { (data, response, error) in
            guard let data = data, error == nil else {
                print("Error downloading image: \(error?.localizedDescription ?? "No error description available")")
                return
            }
            
            if let image = UIImage(data: data) {
                staticInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                MPNowPlayingInfoCenter.default().nowPlayingInfo = staticInfo
                
                // Update MPNowPlayingInfoCenter
                print("Successfully updated Metadata")
            }
        }.resume()
    }
    
    // this function updates the command center metadata that is displayed. It must be called any time a change is made to the video or its state.
    // TODO: This should be made private, SearchVideoView uses it currently
    func updateNowPlayingInfo(for video: Video) {
        print("UPDATING INFO")
        let player = self.getPlayer(for: video)
        let dynamicInfo: [String: Any] = [
            MPMediaItemPropertyPlaybackDuration : NSNumber(value: player.currentItem?.duration.seconds ?? 0.0),
            MPNowPlayingInfoPropertyElapsedPlaybackTime: NSNumber(value: player.currentTime().seconds),
            MPNowPlayingInfoPropertyPlaybackRate : player.rate
        ]

        // This assumes that the nowPlayingInfo has been previously set, so we're merging with existing data.
        if var existingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo {
            for (key, value) in dynamicInfo {
                existingInfo[key] = value
                print("Metadata: Updated values")
            }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = existingInfo
            print("Metadata: Keeping values")

        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = dynamicInfo
            print("Metadata: Reseting values")
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
        self.updateStaticInfo(for: self.getCurrentVideo() ?? EMPTY_VIDEO)
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
    
    private func observeStatus(video: Video, player: AVPlayer) {
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
    
    private func observePlayer(video: Video, to player: AVPlayer) {
    
        if let timeObserverToken = timeObserverToken {
            NotificationCenter.default.removeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        
    //        DispatchQueue.global(qos: .userInitiated).async {
            print("Attached observer to \(player.currentItem)")
    
            player.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                    DispatchQueue.main.async {
                        let duration = player.currentItem?.asset.duration
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
                object: player.currentItem,
                queue: .main
            ) { _ in

                self.playSound()
                self.seekTo(time: CMTime(value: 0, timescale: 1000))
                self.pauseCurrentVideo()
                self.catalog.nextVideo()
                self.playCurrentVideo()

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
