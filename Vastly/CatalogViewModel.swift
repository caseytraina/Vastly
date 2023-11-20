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
import FirebaseFunctions

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
    @Published var playerManager: CatalogPlayerManager?
    @Published var isVideoMode = true
    
    var authModel: AuthViewModel
    
    init(authModel: AuthViewModel) {
        self.isProcessing = true
        self.authModel = authModel
        
        Task {
            await self.getCatalog()
            self.playerManager = CatalogPlayerManager(self.catalog, isVideoMode: self._isVideoMode)
            self.playerManager?.onChange = { [weak self] in
                self?.objectWillChange.send()
            }
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }
    }
    
    func getVideoTime(_ video: Video) -> CMTime {
        return self.playerManager?.playerTimes[video.id] ?? CMTime(value: 0, timescale: 1000)
    }
    
    func getVideoDuration(_ video: Video) -> CMTime {
        return self.playerManager?.getDurationOfVideo(video: video) ?? CMTime(value: 0, timescale: 1000)
    }
    
    func getVideoStatus(_ video: Video) -> VideoStatus {
        self.playerManager?.getStatus(for: video) ?? .loading
    }
    
    func playCurrentVideo() {
        self.trackVideoClicked()
        self.playerManager?.playCurrentVideo()
    }
    
    func pauseCurrentVideo() {
        self.playerManager?.pauseCurrentVideo()
    }
    
    func changeToChannel(_ channel: Channel, shouldPlay: Bool) {
        self.playerManager?.pauseCurrentVideo()
        self.trackVideoWatched()
        self.catalog.changeToChannel(channel)
        self.currentChannel = self.catalog.currentChannel
        self.playerManager?.changeToChannel(channel, shouldPlay: shouldPlay)
        Analytics.channelClicked(channel: channel, user: authModel.user, profile: authModel.current_user)
    }
    
    func changeToNextChannel(shouldPlay: Bool) {
        if let nextChannel = self.catalog.peekNextChannel() {
            self.changeToChannel(nextChannel.channel, shouldPlay: shouldPlay)
        }
    }
    
    func changeToPreviousChannel(shouldPlay: Bool) {
        if let previousChannel = self.catalog.peekPreviousChannel() {
            self.changeToChannel(previousChannel.channel, shouldPlay: shouldPlay)
        }
    }
    
    // This is called right before we actually change the video
    private func trackVideoWatched() {
        if let video = self.catalog.currentVideo {
            let watchedFor = getVideoTime(video).seconds
            let lengthOfVideo = getVideoDuration(video).seconds
            
            if watchedFor > 3 && lengthOfVideo > 0 {
                let percentageWatched = ceil((watchedFor / lengthOfVideo) * 100)
                Analytics.videoWatched(watchTime: watchedFor,
                                       percentageWatched: percentageWatched,
                                       video: video,
                                       user: self.authModel.user,
                                       profile: self.authModel.current_user,
                                       watchedIn: currentChannel.channel)
                
                let db = Firestore.firestore()
                let userKey = self.authModel.current_user?.phoneNumber ?? self.authModel.current_user?.email ?? ""
                let userRef = db.collection("users").document(userKey)
                let videoRef = db.collection("videos").document(video.id)
                let userViewedRef = userRef.collection("viewedVideos").document(video.id)
                userViewedRef.setData([
                    "createdAt": Timestamp(date: Date()),
                    "watchTime": watchedFor,
                    "watchPercentage": percentageWatched,
                    "inChannel": currentChannel.channel.id
                ])
                videoRef.updateData([
                    "viewedCount": FieldValue.increment(Int64(1))
                ])
                self.viewed_videos.insert(video, at: 0)
            }
        }
    }
    
    private func trackVideoClicked() {
        if let video = self.catalog.currentVideo {
            Analytics.videoClicked(video: video, user: authModel.user, profile: authModel.current_user, watchedIn: currentChannel.channel)
        }
    }
    
    func changeToVideoIndex(_ index: Int, shouldPlay: Bool) {
        self.pauseCurrentVideo()
        self.trackVideoWatched()
        self.catalog.changeToVideoIndex(index)
        if shouldPlay {
            self.playCurrentVideo()
        }
    }
    
    func changeToNextVideo(shouldPlay: Bool) {
        self.playerManager?.pauseCurrentVideo()
        self.trackVideoWatched()
        if let nextVideo = self.catalog.nextVideo() {
            if shouldPlay {
                self.playCurrentVideo()
            }
        }
    }

    func changeToPreviousVideo(shouldPlay: Bool) {
        self.playerManager?.pauseCurrentVideo()
        self.trackVideoWatched()
        if let previousVideo = self.catalog.previousVideo() {
            if shouldPlay {
                self.playCurrentVideo()
            }
        }
    }
    
    func toggleVideoMode() {
        self.isVideoMode.toggle()
    }
    
    func getThumbnail(video: Video) -> URL? {
        var urlString = video.url?.absoluteString
        urlString = urlString?.replacingOccurrences(of: "?tr=f-auto", with: "/ik-thumbnail.jpg")
        return URL(string: urlString ?? "")
    }
    
    func videoStatus(_ video: Video) -> VideoStatus {
        return self.playerManager?.getStatus(for: video) ?? .loading
    }
    
    private func populateForYouChannel() async {
        let forYou = ChannelVideos(channel: FOR_YOU_CHANNEL,
                                   profile: self.authModel.current_user,
                                   authors: self.authors)
        let forYouVideos = await self.generateShapedForYou(max: 20)
        for idPlusFirebaseData in forYouVideos {
            forYou.addVideo(id: idPlusFirebaseData.id, unfilteredVideo: idPlusFirebaseData.firebaseData)
        }
        self.catalog.addChannel(forYou)
        self.currentChannel = forYou
        self.changeToChannel(FOR_YOU_CHANNEL, shouldPlay: true)
    }
    
    private func getCatalog() async {
        await self.getChannels()
        await self.getAuthors()
        await self.populateForYouChannel()
        
        let db = Firestore.firestore()
        let storageRef = db.collection("videos")
        // Ignore the "FOR YOU" channel
        for channel in self.channels.dropFirst() {
            let channelVideos = ChannelVideos(channel: channel, 
                                              profile: self.authModel.current_user,
                                              authors: authors)
            
            await self.addVideosTo(channelVideos)
            self.catalog.addChannel(channelVideos)
        }
    }
    
    func setTemporaryChannel(name: String, videos: [Video]) -> Channel {
        let channel = self.catalog.setTemporaryChannel(name: name, videos: videos)
        self.channels.append(channel)
        return channel
    }
    
    func leaveTemporaryChannel(channel: Channel) {
        self.catalog.leaveTemporaryChannel(channel: channel)
        self.channels.removeAll(where: {$0 == channel})
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
                
                let r = (data?["r"] as? Double ?? 115)/255
                let g = (data?["g"] as? Double ?? 79)/255
                let b = (data?["b"] as? Double ?? 255)/255
                
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
    
    func addVideosTo(_ channel: ChannelVideos) async {
        guard let currentUser = self.authModel.current_user else { return  }
        let functions = Functions.functions()
        functions.httpsCallable("getUnviewedVideos").call([
            "userId": currentUser.phoneNumber ?? currentUser.email,
            "channelID" : channel.channel.id]) { (result, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
            
            if let dataArray = result?.data as? [[String: [String: Any]]] {
                // Retrieve the key and value for the first dictionary in the array
                var newVideos: [Video] = []
                for unfilteredVideo in dataArray {
                    let video = self.resultToVideo(
                        id: unfilteredVideo.first?.key ?? UUID().uuidString,
                        data: unfilteredVideo.first?.value)
                    if let video {
                        newVideos.append(video)
                    }
                }
                channel.setVideos(newVideos)
            }
        }
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
    
    // TODO: Below this should be moved to different file
    // This function turns a path to a URL of a cached and compressed video, connecting to our CDN imagekit which is a URL-based video and image delivery and transformation company.
    private func getVideoURL(from location: String) -> URL? {
        var allowedCharacters = CharacterSet.urlQueryAllowed
        allowedCharacters.insert("/")
        
        var fixedPath = location.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
        fixedPath = fixedPath.replacingOccurrences(of: "’", with: "%E2%80%99")
        
        let urlStringUnkept: String = IMAGEKIT_ENDPOINT + fixedPath + "?tr=f-auto"
        if let url = URL(string: urlStringUnkept) {
            return url
        } else {
            print("URL is invalid")
            return EMPTY_VIDEO.url
        }
    }
    
    private func resultToVideo(id: String, data: Any) -> Video? {
        guard let dataDict = data as? [String: Any] else {
            return nil
        }
        
        var video = Video(
            id: id,
            title:  dataDict["title"] as? String ?? "No title found",
            author: self.authors.first(where: { $0.text_id == dataDict["author"] as? String ?? "" }) ?? EMPTY_AUTHOR,
            bio: dataDict["bio"] as? String ?? "",
            date: dataDict["date"] as? String ?? "", // assuming you meant "date" here
            channels: dataDict["channels"] as? [String] ?? [],
            url: self.getVideoURL(from: dataDict["fileName"] as? String ?? ""),
            youtubeURL: dataDict["youtubeURL"] as? String)
        
        
        return video
    }
    
    func fetchLikedVideos() async {
        if let liked_videos = self.authModel.current_user?.likedVideos {
            let db = Firestore.firestore()
            let ref = db.collection("videos")
            
            for id in liked_videos {
                do {
                    let doc = try await ref.document(id).getDocument()
                    if doc.exists {
                        print("Doc Found for \(id)")
                        
                        let data = doc.data()
                        
                        let video = resultToVideo(id: id, data: data)
                        if let video {
                            if !self.authModel.liked_videos.contains(where: { $0.id == video.id }) {
                                DispatchQueue.main.async {
                                    self.authModel.liked_videos.append(video)
                                }
                            }
                        }
                        
                        if self.authModel.liked_videos.count > 5 {
                            DispatchQueue.main.async {
                                self.likedVideosProcessing = false
                            }
                        }
                        
                    } else {
                        print("Doc not found for \(id)")
                    }
                    
                } catch {
                    print("Error getting viewing history: \(error)")
                }
            }
        }
        
        DispatchQueue.main.async {
            self.likedVideosProcessing = false
        }
    }
    
    func fetchViewedVideos() async {
        if let viewed_videos = self.authModel.current_user?.viewedVideos {
            let db = Firestore.firestore()
            let ref = db.collection("videos")
            for id in viewed_videos {
                do {
                    let doc = try await ref.document(id).getDocument()
                    if doc.exists {
                        print("Doc Found for \(id)")
                        
                        let data = doc.data()
                        
                        let video = resultToVideo(id: id, data: data)
                        
                        if let video {
                            if !self.viewed_videos.contains(where: { $0.id == video.id }) {
                                DispatchQueue.main.async {
                                    self.viewed_videos.append(video)
                                }
                            }
                        }
                        
                        if self.viewed_videos.count > 5 {
                            DispatchQueue.main.async {
                                self.viewedVideosProcessing = false
                            }
                        }
                        
                    } else {
                        print("Doc not found for \(id)")
                    }
                    
                } catch {
                    print("Error getting viewing history: \(error)")
                }
            }
        }
        DispatchQueue.main.async {
            self.viewedVideosProcessing = false
        }
    }
}
