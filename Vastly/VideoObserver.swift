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

class VideoPlayerManager: ObservableObject {
    @Published var players: [UUID: AVPlayer] = [:]
    @Published var loadingStates: [UUID: Bool] = [:]
    var current_index: Int = 0
    var activeChannel: Channel = Channel.allCases[0] {
        didSet {
            channel_videos = videos[activeChannel]
        }
    }
    
    var commandCenter: MPRemoteCommandCenter?
    
    @Published var channel_videos: [Video]?
    @Published var videos: [Channel: [Video]] {
        didSet {
            channel_videos = videos[activeChannel]
        }
    }
    
    init(videos: [Channel: [Video]]) {
        self.videos = videos
        updatePlayers(videos: videos)
        channel_videos = videos[activeChannel]
        setupCommandCenter()
//        current_index = x/UserDefaults.standard.integer(forKey: "current_index")

    }
    
    func updatePlayers(videos: [Channel: [Video]]) {
        players = [:] // clear previous players
        self.videos = videos
        for channel in Channel.allCases {
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
    
    func pauseAllOthers(except video: Video) {
        DispatchQueue.main.async {
            for player in self.players {
                if player.key != video.id {
                    player.value.pause()
                }
            }
        }
    }

    func prepareToPlay(_ video: Video) {
        let item = AVPlayerItem(url: video.url ?? URL(string: "www.google.com")!)
        getPlayer(for: video).replaceCurrentItem(with: item)
    }

    func deletePlayer(_ video: Video) {
        getPlayer(for: video).pause()
        self.players[video.id] = nil
    }

    func pause(for video: Video) {
        getPlayer(for: video).pause()
    }

    func play(for video: Video) {
        getPlayer(for: video).play()

    }

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

//        commandCenter.nextTrackCommand.removeTarget(nil)
//        commandCenter.previousTrackCommand.removeTarget(nil)
        
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.isEnabled = true
//        commandCenter.nextTrackCommand.isEnabled = true
//        commandCenter.previousTrackCommand.isEnabled = true

        // Set up command center targets
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.playCurrentVideo()
            self?.pauseAllOthers(except: self?.getCurrentVideo() ?? EMPTY_VIDEO)
            self?.updateNowPlayingInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pauseCurrentVideo()
            self?.updateNowPlayingInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
            
            return .success
        }

        commandCenter.skipForwardCommand.addTarget { [weak self] event -> MPRemoteCommandHandlerStatus in
            if let player = self?.getPlayer(for: self?.getCurrentVideo() ?? EMPTY_VIDEO) {
                let currentTime = player.currentTime().seconds
                player.seek(to: CMTime(seconds: currentTime + 15, preferredTimescale: 1)) // skip forward by 15 seconds
                self?.updateNowPlayingInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
                return .success
            }
            return .commandFailed
        }

        commandCenter.skipBackwardCommand.addTarget { [weak self] event -> MPRemoteCommandHandlerStatus in
            if let player = self?.getPlayer(for: self?.getCurrentVideo() ?? EMPTY_VIDEO) {
                let currentTime = player.currentTime().seconds
                player.seek(to: CMTime(seconds: max(currentTime - 15, 0), preferredTimescale: 1)) // skip backward by 15 seconds, but don't go past the beginning of the track
                self?.updateNowPlayingInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
                return .success
            }
            return .commandFailed
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            if let player = self?.getPlayer(for: self?.getCurrentVideo() ?? EMPTY_VIDEO),
               let event = event as? MPChangePlaybackPositionCommandEvent {
                player.seek(to: CMTime(seconds: event.positionTime, preferredTimescale: 1))
                self?.updateNowPlayingInfo(for: self?.getCurrentVideo() ?? EMPTY_VIDEO)
                return .success
            }
            return .commandFailed
        }
        

        self.commandCenter = commandCenter
    }

    func updateNowPlayingInfo(for video: Video) {
        print("UPDATING INFO")

//        DispatchQueue.global(qos: .userInteractive).async {
        
            var nowPlayingInfo = [String: Any]()
            nowPlayingInfo[MPMediaItemPropertyTitle] = video.title
            
            let player = self.getPlayer(for: video)
            print("running")
            nowPlayingInfo = [
                MPMediaItemPropertyTitle : video.title,
                MPMediaItemPropertyArtist : video.author.name,
                MPMediaItemPropertyAlbumTitle : "Vastly",
                MPMediaItemPropertyPlaybackDuration : NSNumber(value: player.currentItem?.duration.seconds ?? 0.0),
                MPNowPlayingInfoPropertyElapsedPlaybackTime: NSNumber(value: player.currentTime().seconds),
                MPNowPlayingInfoPropertyPlaybackRate : player.rate] as [String : Any]
            
//            if let image = UIImage(named: "AlbumImage.png") {
//                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
//            }
        
        URLSession.shared.dataTask(with: video.author.fileName ?? EMPTY_AUTHOR.fileName!) { (data, response, error) in
            guard let data = data, error == nil else {
                print("Error downloading image: \(error?.localizedDescription ?? "No error description available")")
                return
            }
            
            if let image = UIImage(data: data) {
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                
                // Update MPNowPlayingInfoCenter
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        }.resume()
        
        
        
//            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
//        }
    }

    func nextVideoInChannel() {
        if current_index ?? 0 + 1 < videos[activeChannel]?.count ?? 0 {
            pauseCurrentVideo()
            current_index += 1
            playCurrentVideo()
        }
    }
    
    func previousVideoInChannel() {
        if current_index ?? 0 > 0 {
            pauseCurrentVideo()
            current_index -= 1
            playCurrentVideo()
        }
    }
    
    func changeToIndex(to index: Int, shouldPlay: Bool) {
        if index >= 0 && index < videos[activeChannel]?.count ?? 0 {
            pauseCurrentVideo()
            current_index = index
            if shouldPlay {
                playCurrentVideo()
            }
        }
    }
    
    func changeToChannel(to channel: Channel, shouldPlay: Bool, newIndex: Int) {
        pauseCurrentVideo()
//        channel_index = Channel.allCases.firstIndex(of: channel) ?? 0
        current_index = newIndex
        activeChannel = channel
        if shouldPlay {
            playCurrentVideo()
        }
    }
    
    
    // These are placeholders, replace with your own logic to get the current video
    func playCurrentVideo() {
        guard let currentVideo = getCurrentVideo() else { return }
        play(for: currentVideo)
//        updateNowPlayingInfo(for: currentVideo)
    }
    
//    func nextVideo() {
//        guard let currentVideo = getCurrentVideo() else { return }
//        play(for: currentVideo)
//        updateNowPlayingInfo(for: currentVideo)
//    }

    func pauseCurrentVideo() {
        guard let currentVideo = getCurrentVideo() else { return }
        pause(for: currentVideo)
    }

    func getCurrentVideo() -> Video? {
        if let videos = channel_videos, current_index >= 0 && current_index < videos.count {
            return videos[current_index]
        }
        return nil
    }
}
