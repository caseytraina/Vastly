//
//  CatalogModel.swift
//  Vastly
//
//  Created by Michael Murray on 10/20/23
//

import AVKit
import Combine
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import Foundation
import SwiftUI

// TODO: Track video indices in respective channels

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
    
    var videos: [Video] = []
    var channel: Channel
    // Keep the context of who this is for, for filtering and sorting
    var user: Profile?
    var authors: [Author] = []
    
    var currentVideoIndex = 0
    
    init(channel: Channel, user: Profile?, authors: [Author]) {
        self.user = user
        self.authors = authors
        self.channel = channel
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
    
    func shuffle() {
        self.videos.shuffle()
    }
    
    func changeToVideoIndex(_ index: Int) {
        if (index >= 0 && index < self.videos.count) {
            self.currentVideoIndex = index
        }
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

final class Catalog {
    // This should be kept private, we access the catalog via the public
    // funcs below
    private var catalog: [ChannelVideos] = []
    // Keep an internal track of the history of videos that we have
    // consumed, so we can track state and transitions
    // if they change channel for example, we want to know the last video
    // in the previous channel
    var videoHistory: [Video] = []
    var channelHistory: [ChannelVideos] = []

    var currentVideo: Video?
    var currentChannel: ChannelVideos = ChannelVideos(channel: FOR_YOU_CHANNEL) {
        didSet {
            activeChannel = currentChannel.channel
        }
    }
    // This is just a helper variable to access the channel directly
    var activeChannel: Channel = FOR_YOU_CHANNEL
    
    private var currentChannelIndex = 0
    
    func addChannel(_ channelVideos: ChannelVideos) {
        self.catalog.append(channelVideos)
    }
    
    func channels() -> [Channel] {
        return self.catalog.map { channelVideos in channelVideos.channel }
    }
    
    func channelVideos() -> [ChannelVideos] {
        return self.catalog
    }
    
    func hasNextChannel() -> Bool {
        let totalChannels = self.catalog.count
        return self.currentChannelIndex < (totalChannels - 1)
    }
    
    func hasPreviousChannel() -> Bool {
        return self.currentChannelIndex > 0
    }
      
    func currentVideoIndex() -> Int? {
        return currentChannel.currentVideoIndex
    }
    
    func peekPreviousChannel() -> ChannelVideos? {
        return channelHistory.last
    }
    
    func nextChannel() -> ChannelVideos? {
        if hasNextChannel() {
            self.updateChannelHistory()
            self.currentChannelIndex += 1
            self.currentChannel = self.catalog[self.currentChannelIndex]
            return self.currentChannel
        } else {
            return nil
        }
    }
    
    func previousChannel() -> ChannelVideos? {
        if hasPreviousChannel() {
            self.updateChannelHistory()
            self.currentChannelIndex -= 1
            self.currentChannel = self.catalog[self.currentChannelIndex]
            return self.currentChannel
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
    
    func changeToChannel(_ channel: Channel) {
        if let newChannelIndex = self.catalog.firstIndex(where: { channelVideo in
            return channelVideo.channel == channel
        }) {
            self.updateChannelHistory()
            self.currentChannelIndex = newChannelIndex
            self.currentChannel = self.catalog[newChannelIndex]
            self.changeToVideoIndex(0)
        }
    }
    
    func getVideo(id: String) -> Video? {
        var foundVideo: Video? = nil
        self.catalog.forEach { channelVideos in
            foundVideo = channelVideos.videos.first(where: { video in
                return video.id == id
            })
        }
        return foundVideo
    }
    
    private func updateChannelHistory() {
        channelHistory.append(currentChannel)
    }
    
    private func updateVideoHistory() {
        if let currentVideo = currentVideo {
            videoHistory.append(currentVideo)
        }
    }
}

class CatalogViewModel: ObservableObject {
    @Published var isProcessing: Bool
    @Published var catalog: Catalog = Catalog()
    @Published var currentChannel: ChannelVideos = ChannelVideos(channel: FOR_YOU_CHANNEL)
    
    // This is private, channels should be accessed via the catalog, this
    // is only used to populate the catalog
    private var channels: [Channel] = [FOR_YOU_CHANNEL]
    var authors: [Author] = []
    
    @Published var viewedVideosProcessing: Bool = true
    @Published var likedVideosProcessing: Bool = true

    @Published var viewed_videos: [Video] = []
    
    // This public interface should be read-only, we should't be playing / pausing
    // or seeking via this variable, that should be handled in the public funcs below
    var playerManager: CatalogPlayerManager?
    
    var authModel: AuthViewModel
    
    init(authModel: AuthViewModel) {
        self.isProcessing = true
        self.authModel = authModel

        Task {
            await self.getCatalog()
            self.playerManager = CatalogPlayerManager(self.catalog)
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }
    }
    
    func playCurrentVideo() {
        if let video = self.currentChannel.currentVideo() {
            self.playerManager?.play(for: video)
        }
    }
    
    func changeToChannel(_ channel: Channel, shouldPlay: Bool) {
        self.playerManager?.pauseCurrentVideo()
        self.catalog.changeToChannel(channel)
        self.currentChannel = self.catalog.currentChannel
        self.playerManager?.changeToChannel(to: channel, shouldPlay: shouldPlay)
    }
    
    func changeToNextChannel(shouldPlay: Bool) {
        self.playerManager?.pauseCurrentVideo()
        if let newChannel = self.catalog.nextChannel() {
            self.currentChannel = self.catalog.currentChannel
            self.playerManager?.changeToChannel(to: newChannel.channel, shouldPlay: shouldPlay)
        }
    }
    
    func changeToPreviousChannel(shouldPlay: Bool) {
        self.playerManager?.pauseCurrentVideo()
        if let newChannel = self.catalog.previousChannel() {
            self.currentChannel = self.catalog.currentChannel
            self.playerManager?.changeToChannel(to: newChannel.channel, shouldPlay: shouldPlay)
        }
    }
    
    func changeToNextVideo() {
        self.playerManager?.pauseCurrentVideo()
        if let nextVideo = self.catalog.nextVideo() {
            self.currentChannel = self.catalog.currentChannel
            self.playerManager?.play(for: nextVideo)
        }
    }
    
    func changeToPreviousVideo() {
        self.playerManager?.pauseCurrentVideo()
        if let previousVideo = self.catalog.previousVideo() {
            self.currentChannel = self.catalog.currentChannel
            self.playerManager?.play(for: previousVideo)
        }
    }
    
    private func populateForYouChannel() async {
        let forYou = ChannelVideos(channel: FOR_YOU_CHANNEL,
                                   user: self.authModel.current_user,
                                   authors: self.authors)
        let forYouVideos = await self.generateShapedForYou(max: 20)
        for idPlusFirebaseData in forYouVideos {
            forYou.addVideo(id: idPlusFirebaseData.id, unfilteredVideo: idPlusFirebaseData.firebaseData)
        }
        self.catalog.addChannel(forYou)
        self.currentChannel = forYou
    }
    
    private func getCatalog() async {
        await self.getChannels()
        await self.getAuthors()
        await self.populateForYouChannel()
        
        let db = Firestore.firestore()
        let storageRef = db.collection("videos")
        // Ignore the "FOR YOU" channel
        for channel in self.channels.dropFirst() {
            do {
                let channelVideos = ChannelVideos(channel: channel, user: self.authModel.current_user, authors: authors)
                
                let snapshot = try await storageRef
                    .whereField("channels", arrayContains: channel.id)
                    .order(by: "likedCount", descending: true)
                    .limit(to: 15).getDocuments()
                
                for document in snapshot.documents {
                    let unfilteredVideo = try document.data(as: FirebaseData.self)
                    let id = document.documentID
                    channelVideos.addVideo(id: id, unfilteredVideo: unfilteredVideo)
                }
                self.catalog.addChannel(channelVideos)
            } catch {
                print("error with video: \(error)")
            }
        }
    }
    
    // This function queries all of the authors from firebase, housing them in a local array to be used to apply to videos.
    private func getAuthors() async {
        let db = Firestore.firestore()
        let storageRef = db.collection("authors")
        
        do {
            let documents = try await fetchDocuments(in: storageRef)
            
            for document in documents {
                let data = document.data()
                let author = Author(
                    id: UUID(),
                    text_id: document.documentID,
                    name: data?["name"] as? String ?? "",
                    bio: data?["bio"] as? String ?? "",
                    fileName: self.pathToURL("Author Logos/\(data?["fileName"] ?? "")"),
                    website: data?["website"] as? String ?? "",
                    apple: data?["apple"] as? String ?? "",
                    spotify: data?["spotify"] as? String ?? "")
                self.authors.append(author)
            }
            
        } catch {
            print("error retrieving authors: \(error)")
        }
    }
    
    // This function queries all of the channels from firebase, housing them in a local array to be used to apply to videos.
    private func getChannels() async {
        let db = Firestore.firestore()
        let storageRef = db.collection("channels")
        
        do {
            let documents = try await fetchDocuments(in: storageRef)
            
            for document in documents {
                let data = document.data()
                
                let r = (data?["r"] as? Double ?? 0.0)/255
                let g = (data?["g"] as? Double ?? 0.0)/255
                let b = (data?["b"] as? Double ?? 0.0)/255
                
                let channel = Channel(
                    id: document.documentID,
                    order: data?["order"] as? Int ?? 0,
                    title: data?["title"] as? String ?? document.documentID,
                    color: Color(red: r, green: g, blue: b),
                    isActive: data?["isActive"] as? Bool ?? false)
                if channel.isActive {
                    DispatchQueue.main.async {
                        self.channels.append(channel)
                    }
                }
            }
            
        } catch {
            print("error retrieving channels: \(error)")
        }
    }
    
    // This function turns a path to a URL of a thumbnail, connecting to our CDN imagekit which is a URL-based video and image delivery and transformation company.
    private func pathToURL(_ path: String) -> URL {
//        let FIREBASE_ENDPOINT = "https://firebasestorage.googleapis.com/v0/b/rizeo-40249.appspot.com/o/"
//        var fixedPath = path.replacingOccurrences(of: " ", with: "%20")
//        fixedPath = fixedPath.replacingOccurrences(of: "/", with: "%2F")

        var allowedCharacters = CharacterSet.urlQueryAllowed
        allowedCharacters.insert("/")
        
        let fixedPath = path.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""

        let urlStringUnkept: String = IMAGEKIT_ENDPOINT + fixedPath
        
        return URL(string: urlStringUnkept) ?? URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/46/Question_mark_%28black%29.svg/800px-Question_mark_%28black%29.svg.png")!
    }
    
    // This function accepts a storage regerence and returns all documents at the given reference in Firebase.
    private func fetchDocuments(in storageRef: CollectionReference) async throws -> [DocumentSnapshot] {
        let snapshot = try await storageRef.getDocuments()
        return snapshot.documents
    }

    private func fetchValueFromPlist(key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject]
        else {
            return nil
        }
        
        return dict[key] as? String
    }
    
    private struct ShapedResponse: Codable {
        var ids: [String]
        var scores: [Double]
    }
    
    private struct IdPlusFirebaseData {
        var id: String
        var firebaseData: FirebaseData
    }
    private func generateShapedForYou(max: Int) async -> [IdPlusFirebaseData] {
        var channelVideos: [IdPlusFirebaseData] = []
        let userId = self.authModel.user?.phoneNumber ?? self.authModel.user?.email ?? ""
        var rankURL = URLComponents(string: "https://api.prod.shaped.ai/v1/models/video_recommendations_percentages/rank")!
        let queryItems = [
            URLQueryItem(name: "user_id", value: userId),
            URLQueryItem(name: "limit", value: String(max)),
            URLQueryItem(name: "return_metadata", value: "false")
        ]
        rankURL.queryItems = queryItems
        var request = URLRequest(url: rankURL.url!)
        
        let key: String = self.fetchValueFromPlist(key: "SHAPED_API_KEY") ?? ""

        request.addValue(key,
                         forHTTPHeaderField: "x-api-key")
        
        let urlSession = URLSession.shared
        let (data, _) = try! await urlSession.data(for: request)
        do {
            let json = try JSONDecoder().decode(ShapedResponse.self, from: data)
            let db = Firestore.firestore()
            let videosRef = db.collection("videos")
            for videoId in json.ids {
                do {
                    // this doesn't seem to work right when you do an `in` query
                    // preserve the order here as they will be ranked from shaped
                    
                    // the shaped model will handle filtering out videos
                    // which have been viewed already
                    let document = try await videosRef.document(videoId).getDocument()
                    let unfilteredVideo = try document.data(as: FirebaseData.self)
                    let id = document.documentID
                    channelVideos.append(IdPlusFirebaseData(id: id, firebaseData: unfilteredVideo))
                } catch {
                    print("error looking up videos: \(error)")
                }
            }

        } catch {
            print("error looking up shaped api: \(error)")
        }
        return channelVideos
    }
}
