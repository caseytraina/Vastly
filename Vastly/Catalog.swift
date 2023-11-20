//
//  Catalog.swift
//  Vastly
//
//  Created by Michael Murray on 11/20/23.
//

import Foundation
import Firebase
import FirebaseFirestore

/*
 CatalogModel is responsible for the querying and handling of video data in-app. CatalogModel handles all video operations, except for the actual playing of the videos. That is controlled in VideoObserver.
 */

class ChannelVideos: Identifiable, Hashable {
    static func == (lhs: ChannelVideos, rhs: ChannelVideos) -> Bool {
        lhs.channel == rhs.channel
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(channel.id)
    }
    
    private(set) var channel: Channel
    // Keep the context of who this is for, for filtering and sorting
    private(set) var user: Profile?
    private(set) var authors: [Author] = []
    
    // Don't access these directly, use the public functions
    private(set) var videos: [Video] = []
    private(set) var currentVideoIndex = 0
    
    init(channel: Channel, user: Profile?, authors: [Author]) {
        self.user = user
        self.authors = authors
        self.channel = channel
    }
    
    init(channel: Channel, videos: [Video]) {
        self.channel = channel
        self.videos = videos
    }
    
    init(channel: Channel) {
        self.channel = channel
    }
    
    func addVideo(id: String, unfilteredVideo: FirebaseData) {
        let punctuation: Set<Character> = ["?", "@", "#", "%", "^", "*"]
        if !(user?.viewedVideos?.contains(where: { $0 == id }) ?? false) {
            if var loc = unfilteredVideo.location {
                loc.removeAll(where: { punctuation.contains($0) })
                let unprocessedVideo = UnprocessedVideo(
                    id: id,
                    title: unfilteredVideo.title ?? "Unknown Title",
                    author: unfilteredVideo.author ?? "The author for this video cannot be found.",
                    bio: unfilteredVideo.bio ?? "The bio for this video cannot be found. Please look online for more information.",
                    date: unfilteredVideo.date,
                    channels: unfilteredVideo.channels ?? ["none"],
                    location: "\(loc)",
                    youtubeURL: unfilteredVideo.youtubeURL)
                let video = processVideo(unprocessedVideo)
                videos.append(video)
            }
        }
    }
    
    func setVideos(_ videos: [Video]) {
        self.videos = videos
    }
    
    func hasNextVideo() -> Bool {
        let totalVideos = self.videos.count
        return self.currentVideoIndex < (totalVideos - 1)
    }
    
    func hasPreviousVideo() -> Bool {
        return self.currentVideoIndex > 0
    }
    
    func currentVideo() -> Video? {
        if self.videos.isEmpty {
            return nil
        }
        return self.videos[self.currentVideoIndex]
    }
    
    func nextVideo() -> Video? {
        if hasNextVideo() {
            self.currentVideoIndex += 1
            return self.currentVideo()
        } else {
            return nil
        }
    }
    
    func peekNextVideo() -> Video? {
        if hasNextVideo() {
            return self.videos[self.currentVideoIndex + 1]
        } else {
            return nil
        }
    }
    
    func previousVideo() -> Video? {
        if hasPreviousVideo() {
            self.currentVideoIndex -= 1
            return self.currentVideo()
        } else {
            return nil
        }
    }
    
    func changeToVideoIndex(_ index: Int) {
        if (index >= 0 && index < self.videos.count) {
            self.currentVideoIndex = index
        }
    }
        
    func getVideo(id: String) -> Video? {
        var foundVideo: Video? = nil
        foundVideo = self.videos.first(where: { video in
            return video.id == id
        })
        return foundVideo
    }
    
    private func findAuthor(_ video: UnprocessedVideo) -> Author {
        for author in self.authors {
            if video.author.trimmingCharacters(in: .whitespacesAndNewlines) == author.text_id?.trimmingCharacters(in: .whitespacesAndNewlines) {
                return author
            }
        }
        return EMPTY_AUTHOR
    }
    
    private func processVideo(_ video: UnprocessedVideo) -> Video {
        return Video(id: video.id,
                     title: video.title,
                     author: self.findAuthor(video),
                     bio: video.bio,
                     date: video.date,
                     channels: video.channels,
                     url: video.getVideoURL(),
                     youtubeURL: video.youtubeURL)
        }
}

// The data structure for videos and channels, this maintains the state of
// where the user is in the application, which video and channel they are in
// what is next and previous and history etc.
// This should not know anything about video players, that is handled in the
// CatalogViewModel
final class Catalog {
    // This should be kept private, we access the catalog via the public
    // funcs below
    private var catalog: [ChannelVideos] = []
    // Keep an internal track of the history of videos that we have
    // consumed, so we can track state and transitions
    // if they change channel for example, we want to know the last video
    // in the previous channel
        
    private(set) var videoHistory: [Video] = []
    private(set) var channelHistory: [ChannelVideos] = []
    
    private(set) var currentVideo: Video?
    private(set) var currentChannel: ChannelVideos = ChannelVideos(channel: FOR_YOU_CHANNEL) {
        didSet {
            activeChannel = currentChannel.channel
        }
    }
    // This is just a helper variable to access the channel directly
    private(set) var activeChannel: Channel = FOR_YOU_CHANNEL
    var user: User?
    var profile: Profile?
    
    // This is the main control for which channel we are in, this is the main
    // source of truth in this model
    private var currentChannelIndex = 0
    
    func addChannel(_ channelVideos: ChannelVideos) {
        self.catalog.append(channelVideos)
    }
    
    func channels() -> [Channel] {
        return self.catalog.map { channelVideos in channelVideos.channel }
    }
    
    func hasNextChannel() -> Bool {
        let totalChannels = self.catalog.count
        return self.currentChannelIndex < (totalChannels - 1)
    }
    
    private func removeChannel(_ channel: Channel) {
        self.catalog.removeAll(where: {$0.channel == channel})
    }
    
    func setTemporaryChannel(name: String, videos: [Video]) -> Channel {
        let channel = Channel(id: UUID().uuidString, order: 0, title: name, color: .white, isActive: false)
        let channelVideos = ChannelVideos(channel: channel, videos: videos)
        self.addChannel(channelVideos)
        self.changeToChannel(channelVideos)
        return channel
    }
    
    func leaveTemporaryChannel(channel: Channel) {
        if let previousChannel = peekPreviousChannelInHistory() {
            self.changeToChannel(previousChannel)
            self.removeChannel(channel)
        }
    }
    
    func hasPreviousChannel() -> Bool {
        return self.currentChannelIndex > 0
    }
      
    func currentVideoIndex() -> Int? {
        return currentChannel.currentVideoIndex
    }
    
    func channelVideos(for channel: Channel) -> [Video]? {
        return self.catalog.first(where:  { $0.channel == channel })?.videos
    }
    
    // You can navigate to a channel not next, so this maintains that order
    // if you want the next channel in the carousel then use peekPreviousChannel
    func peekPreviousChannelInHistory() -> ChannelVideos? {
        return channelHistory.last
    }
    
    func peekPreviousChannel() -> ChannelVideos? {
        if hasPreviousChannel() {
            return self.catalog[self.currentChannelIndex - 1]
        } else {
            return nil
        }
    }
    
    func peekNextChannel() -> ChannelVideos? {
        if hasNextChannel() {
            return self.catalog[self.currentChannelIndex + 1]
        } else {
            return nil
        }
    }
    
    func nextVideo() -> Video? {
        self.updateVideoHistory()
        if let nextVideo = currentChannel.nextVideo() {
            self.currentVideo = nextVideo
        }
        return self.currentVideo
    }
    
    func previousVideo() -> Video? {
        self.updateVideoHistory()
        if let previousVideo = currentChannel.previousVideo() {
            currentVideo = previousVideo
        }
        return currentVideo
    }
    
    func peekNextVideo() -> Video? {
        currentChannel.peekNextVideo()
    }
    
    func peekPreviousVideo() -> Video? {
        return videoHistory.last
    }
    
    func changeToVideoIndex(_ index: Int) {
        self.updateVideoHistory()
        self.currentChannel.changeToVideoIndex(index)
        let vid = self.currentChannel.currentVideo()
        self.currentVideo = vid
    }
    
    func changeToChannel(_ channel: ChannelVideos) {
        self.changeToChannel(channel.channel)
    }
    
    func changeToChannel(_ channel: Channel) {
        if let newChannelIndex = self.catalog.firstIndex(where: { channelVideo in
            return channelVideo.channel == channel
        }) {
            self.updateChannelHistory()
            self.currentChannelIndex = newChannelIndex
            self.currentChannel = self.catalog[newChannelIndex]
            let currentVideoIndex = self.currentChannel.currentVideoIndex
            self.changeToVideoIndex(currentVideoIndex)
        }
    }
    
    func getVideo(id: String) -> Video? {
        var foundVideo: Video? = nil
        self.catalog.forEach { channelVideos in
            foundVideo = channelVideos.getVideo(id: id)
            if foundVideo != nil {
                return
            }
        }
        return foundVideo
    }
    
    private func updateChannelHistory() {
        channelHistory.append(currentChannel)
    }
    
    // This is called to log the current video before moving to the next
    private func updateVideoHistory() {
        if let currentVideo = currentVideo {
            videoHistory.append(currentVideo)
        }
    }
}
