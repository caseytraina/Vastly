//
//  VideoObserver.swift
//  Vastly
//
//  Created by Casey Traina on 6/12/23.
//

import Foundation
import AVKit
import SwiftUI
import MediaPlayer

/*
 This View Model governs all AVPlayers and their states, and controls the starting and stopping of videos. This exists as a child of the VideoViewModel. A given video can be described by its channel and current_index. videos[.foryou][0] describes the first video in the for you channel. Players is a flat array which correlates to videos based on their UUIDs
 */

class VideoPlayerManager: ObservableObject {
    
    @Published var players: [String: AVPlayer] = [:]
    @Published var loadingStates: [String: Bool] = [:]
    
    var current_index: Int = 0
    var activeChannel: Channel = FOR_YOU_CHANNEL {
        didSet {
            queue = videos[activeChannel]
        }
    }
    
    var commandCenter: MPRemoteCommandCenter?
    
    @Published var queue: [Video]?
    @Published var videos: [Channel: [Video]] {
        didSet {
            queue = videos[activeChannel]
        }
    }
    
    
    
    // initialize players as well as channel_videos and the command center. The command center must be setup once.
    // the channel_videos is for ease-of-use.
    
    init(videos: [Channel: [Video]]) {
        print("INIT: Video Player Manager")
        self.videos = videos
//        updatePlayers(videos: videos)
        queue = videos[activeChannel]
        setupCommandCenter()
//        current_index = x/UserDefaults.standard.integer(forKey: "current_index")

    }
    
    // To limit memory, this function no longer does anything except update the value of videos.
    func updatePlayers(videos: [Channel: [Video]]) {
        players = [:] // clear previous players
        self.videos = videos
        for channel in videos.keys {
            if let vids = videos[channel] {
                for video in vids {
//                    let player = AVPlayer()
//                    player.automaticallyWaitsToMinimizeStalling = false
//                    player.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
//                    players[video.id] = player
                }
            }
        }
    }
    
    // This function returns the AVPlayer for a given video by matching its UUID to one in the players array. If one does not exist, it is created and returned.
    func getPlayer(for video: Video) -> AVPlayer {
        if let player = players[video.id] {
            if player.currentItem == nil {
                let item = AVPlayerItem(url: video.url ?? URL(string: "www.google.com")!)
                item.preferredPeakBitRate = 4000000
                item.preferredPeakBitRateForExpensiveNetworks = 3000000
                
                player.replaceCurrentItem(with: item)
            }
            return player
        } else {
            let player = AVPlayer(url: video.url ?? URL(string: "www.google.com")!)

            players[video.id] = player
            return player
        }
    }
    
    // This function loops through the existing players and pauses them except for the one given.
    func pauseAllOthers(except video: Video) {
        DispatchQueue.main.async {
            for player in self.players {
                if player.key != video.id {
                    player.value.pause()
                }
            }
        }
    }

    // This function ensures that a player for a given video has been created.
    func prepareToPlay(_ video: Video) {
        let item = AVPlayerItem(url: video.url ?? URL(string: "www.google.com")!)
        getPlayer(for: video).replaceCurrentItem(with: item)
    }

    // This function deletes an AVPlayer, clearing memory after it has been used. AVPlayers are expensive to create and slow down the app.
    func deletePlayer(_ video: Video) {
        getPlayer(for: video).pause()
        self.players[video.id] = nil
    }

    // pauses the video.
    func pause(for video: Video) {
        getPlayer(for: video).pause()
    }
    
    // plays the video.
    func play(for video: Video) {
        getPlayer(for: video).play()

    }

    // this function initializes the physical command center controls.
    func setupCommandCenter() {
        print("SETUP")
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
            self?.pauseAllOthers(except: self?.getCurrentVideo() ?? EMPTY_VIDEO)
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
    
    func updateQueue(with videos: [Video]) {
        self.queue = videos
    }

    // Function to update static metadata
    func updateStaticInfo(for video: Video) {
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

    // This function plays the next video in the currently active channel.
    func nextVideo() {
        if current_index ?? 0 + 1 < queue?.count ?? 0 {
            pauseCurrentVideo()
            current_index += 1
            playCurrentVideo()
        }
    }
    
    // This function plays the previous video in the currently active channel.
    func previousVideo() {
        if current_index ?? 0 > 0 {
            pauseCurrentVideo()
            current_index -= 1
            playCurrentVideo()
        }
    }
    
    // this video changes the current video to a new index in the same active channel.
    func changeToIndex(to index: Int, shouldPlay: Bool) {
        if index >= 0 && index < queue?.count ?? 0 {
            pauseCurrentVideo()
            current_index = index
            self.updateStaticInfo(for: self.getCurrentVideo() ?? EMPTY_VIDEO)
            if shouldPlay {
                playCurrentVideo()
            }
        }
    }
    
    // this function facilitates a change in channel and current_index.
    func changeToChannel(to channel: Channel, shouldPlay: Bool, newIndex: Int) {
        pauseCurrentVideo()
//        channel_index = Channel.allCases.firstIndex(of: channel) ?? 0
        current_index = newIndex
        activeChannel = channel
        self.updateStaticInfo(for: self.getCurrentVideo() ?? EMPTY_VIDEO)
        if shouldPlay {
            playCurrentVideo()
        }
        

    }
    
    
    // This function plays the current video.
    func playCurrentVideo() {
        guard let currentVideo = getCurrentVideo() else { return }
        play(for: currentVideo)
//        updateNowPlayingInfo(for: currentVideo)
    }
    
    func seekForward(by increment: Double) {
        if let video = self.getCurrentVideo() {
            let player = self.getPlayer(for: video)
            let currentTime = player.currentTime().seconds
            player.seek(to: CMTime(seconds: currentTime + increment, preferredTimescale: 1)) // skip forward by 15 seconds
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
    
    // This function pauses the current video.
    func pauseCurrentVideo() {
        guard let currentVideo = getCurrentVideo() else { return }
        pause(for: currentVideo)
    }

    // This function returns the current video.
    func getCurrentVideo() -> Video? {
        if let videos = queue, current_index >= 0 && current_index < videos.count {
            return videos[current_index]
        }
        return nil
    }
}
