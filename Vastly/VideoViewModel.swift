//
//  Storage.swift
//  Vastly
//
//  Created by Casey Traina on 5/10/23.
//


import Foundation
import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import AVKit
import Combine
import FirebaseFirestoreSwift
//import ImageKitIO

/*
 VideoViewModel is responsible for the querying and handling of video data in-app. VideoViewModel handles all video operations, except for the actual playing of the videos. That is controlled in VideoObserver.
 */


class VideoViewModel: ObservableObject {
    
    @Published var videos: [Channel: [Video]] = [:]
        
    @Published var isProcessing: Bool = true {
        didSet {
            self.playerManager = VideoPlayerManager(videos: self.videos)
        }
    }
    
//    @Published var trendingVideos: [Video] = []
    
    var authors: [Author] = []
    
    var playerManager: VideoPlayerManager?
    
    init() {
        // Initialize player manager here.
        
        Task {
            var myVideos: [Channel: [UnprocessedVideo]] = [:]
            //            for channel in Channel.allCases {
            //                print(channel)
            do {
                
                myVideos = try await self.getChannels()
                print("got videos.")
                await getAuthors()
                print("got authors")
                processUnprocessedVideos(unprocessedVideos: myVideos)
//                attachAuthors()
                print("Processed videos")
            } catch {
                print("Error getting videos: \(error)")
                DispatchQueue.main.async {
                    self.isProcessing = false

                }
            }
            //            }
        }
        
    }
    
        // This turns the string representing an author in an UnprocessedVideo into a type Author, which can be used to translate into type Video.
    func findAuthor(_ video: UnprocessedVideo) -> Author {
        for author in self.authors {
            if video.author.trimmingCharacters(in: .whitespacesAndNewlines) == author.text_id?.trimmingCharacters(in: .whitespacesAndNewlines) {
                return author
            }
        }
        return EMPTY_AUTHOR
    }
    
    // This function queries and returns all videos. Videos are organized by channels, hence the 2D array and getChannels name.
    func getChannels() async throws -> [Channel: [UnprocessedVideo]] {
        var videosDict: [Channel : [UnprocessedVideo]] = [:]
        
        let db = Firestore.firestore()
        let storageRef = db.collection("videos")
        
        let documents = try await fetchDocuments(in: storageRef)
        do {
            for document in documents {
                let unfilteredVideo = try document.data(as: FirebaseData.self)
                let punctuation: Set<Character> = ["?", "@", "#", "%", "^", "*"]
                
                if var loc = unfilteredVideo.location {
                    loc.removeAll(where: { punctuation.contains($0) })
                    let video = UnprocessedVideo(
                        title: unfilteredVideo.title ?? "Unknown Title",
                        author: unfilteredVideo.author ?? "The author for this video cannot be found.",
                        bio: unfilteredVideo.bio ?? "The bio for this video cannot be found. Please look online for more information.",
                        date: unfilteredVideo.date,
                        channels: unfilteredVideo.channels ?? ["none"],
                        location: "\(loc)",
                        youtubeURL: unfilteredVideo.youtubeURL)
                    print(loc)
                    
                    for channelItem in video.channels {
                        if let channel = Channel(rawValue: channelItem) {
                            if videosDict[channel] != nil {
                                videosDict[channel]!.append(video)
                            } else {
                                videosDict[channel] = [video]
                            }
                        }
                    }
                }
            }
        } catch {
            print("error with video: \(error)")
        }
        
        return videosDict
    }
    
    // This function queries all of the authors from firebase, housing them in a local array to be used to apply to videos.
    func getAuthors() async {
        let db = Firestore.firestore()
        let storageRef = db.collection("authors")
        
        do {
            let documents = try await fetchDocuments(in: storageRef)
            
            for document in documents {
                let data = document.data()
                
                if let location = data?["fileName"] {
                    var author = Author(
                        id: UUID(),
                        text_id: document.documentID,
                        name: data?["name"] as? String ?? "",
                        bio: data?["bio"] as? String ?? "",
                        fileName: pathToURL("Author Logos/\(location)" ),
                        website: data?["website"] as? String ?? "",
                        apple: data?["apple"] as? String ?? "",
                        spotify: data?["spotify"] as? String ?? "")
                    self.authors.append(author)

                } else {
                    var author = Author(
                        id: UUID(),
                        text_id: document.documentID,
                        name: data?["name"] as? String ?? "",
                        bio: data?["bio"] as? String ?? "",
                        fileName: pathToURL("Author Logos/\(data?["fileName"] ?? "")"),
                        website: data?["website"] as? String ?? "",
                        apple: data?["apple"] as? String ?? "",
                        spotify: data?["spotify"] as? String ?? "")
                    self.authors.append(author)
                }
            }
            
        } catch {
            print("error retrieving authors: \(error)")
        }
    }
    
    // This function turns a path to a URL of a thumbnail, connecting to our CDN imagekit which is a URL-based video and image delivery and transformation company.
    func pathToURL(_ path: String) -> URL {
        
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
    func fetchDocuments(in storageRef: CollectionReference) async throws -> [DocumentSnapshot] {
        let db = Firestore.firestore()
        let snapshot = try await storageRef.getDocuments()
        return snapshot.documents
    }

    
    // This video accepts the 2D array of unprocessed videos and populates the VideoPlayerManager (found in VideoObserver). This is where videos are added to the for you tab.
    func processUnprocessedVideos(unprocessedVideos: [Channel: [UnprocessedVideo]]) {
        Task {
            do {
                let processedVideos = try await processVideos(videos: unprocessedVideos)
                DispatchQueue.main.async {
                    self.videos = processedVideos
                    self.videos[Channel.foryou] = self.getRandomVideos(maxCount: 40)
//                    self.trendingVideos = self.getRandomVideos(maxCount: 40)
                    self.playerManager?.updatePlayers(videos: self.videos)
                    self.isProcessing = false
                    //                    }
                }
            } catch {
                // handle error
                print("Error processing videos: \(error)")
                DispatchQueue.main.async {
                    if (self.videos.keys.count == Channel.allCases.count) {
                        self.videos[Channel.foryou] = self.getRandomVideos(maxCount: 40)
                        self.playerManager?.updatePlayers(videos: self.videos)
                        self.isProcessing = false
                    }
                }
            }
        }
    }
    
    // This function turns a path to a URL of a cached and compressed video, connecting to our CDN imagekit which is a URL-based video and image delivery and transformation company.
    func getAVPlayer(from location: String) async throws -> URL? {

//        let urlStringUnkept: String = IMAGEKIT_ENDPOINT + location + "?tr=f-webm"
//        let FIREBASE_ENDPOINT = "https://firebasestorage.googleapis.com/v0/b/rizeo-40249.appspot.com/o/"
//        var fixedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
//        var fixedLocation = location.replacingOccurrences(of: " ", with: "%20")
        var allowedCharacters = CharacterSet.urlQueryAllowed
        allowedCharacters.insert("/")
        
        var fixedPath = location.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
        fixedPath = fixedPath.replacingOccurrences(of: "’", with: "%E2%80%99")
        let urlStringUnkept: String = IMAGEKIT_ENDPOINT + fixedPath + "?tr=f-auto"
        var urlString = urlStringUnkept

        print(urlString)
        if let url = URL(string: urlString ?? "") {
            return url
        } else {
            return EMPTY_VIDEO.url
            print("URL is invalid")
        }
    }
    
    // This function accepts the UnprocessedVideos and processes each of them and returns an array of processed videos
    func processVideos(videos: [Channel : [UnprocessedVideo]]) async throws -> [Channel: [Video]] {
        var processedVideos: [Channel: [Video]] = [:]
        var count = 0
        // loop through unprocessed
        for video in Array(videos.values.flatMap { $0 }) {
            do {
                // await used since getAVPlayer returns async.
                let player = try await getAVPlayer(from: video.location)
                let processedVideo = Video(id: UUID(), title: video.title, author: findAuthor(video), bio: video.bio, date: video.date, channels: video.channels, url: player, youtubeURL: video.youtubeURL)
                count += 1
                
                for channelItem in processedVideo.channels {
                    if let channel = Channel(rawValue: channelItem) {
                        if processedVideos[channel] != nil {
                            processedVideos[channel]!.append(processedVideo)
                        } else {
                            processedVideos[channel] = [processedVideo]
                        }
                    }
                }
                
            } catch {
                //            processedVideos.append(EMPTY_VIDEO)
                //            count += 1
                print("error processing video array: \(error)")
            }
        }
        
        for channel in processedVideos.keys {
            processedVideos[channel] = processedVideos[channel]?.shuffled().shuffled()
        }
        
        return processedVideos
    }
    // This function accepts an integer n and returns a random array consistent of n videos.
    func getRandomVideos(maxCount: Int) -> [Video] {
        // Convert the dictionary to a flat array
        let allVideos = Array(videos.values.flatMap { $0 })
        
        // If allVideos is empty or maxCount is 0, return an empty array
        guard !allVideos.isEmpty, maxCount > 0 else {
            return []
        }
        
        var randomVideos: [Video] = []
        for _ in 0..<min(maxCount, allVideos.count) {
            let randomIndex = Int.random(in: 0..<allVideos.count)
            
            // Get a random video
            let video = allVideos[randomIndex]
                        
            // Create a new video with the same properties, but with "For You" as the channel
            var newVideo = Video(id: video.id,
                                 title: video.title,
                                 author: video.author,
                                 bio: video.bio,
                                 date: video.date,
                                 channels: ["For You"],
                                 url: video.url,
                                 youtubeURL: video.youtubeURL)
//            newVideo.channels.append("For You")
            
            //            if !video.channels.contains("For You") {
            //                video.channels.append("")
            //            }
            
            if !randomVideos.contains(where: { $0.id == newVideo.id }) {
                randomVideos.append(newVideo)
            }
        }
        
        return randomVideos.shuffled().shuffled()
    }
    
//    func getTrendingVideos() {
//        DispatchQueue.main.async {
//        }
//    }
    
//    func addTrendingVideos() {
//        for video in self.getRandomVideos(maxCount: 40) {
//            
//            if !trendingVideos.contains(where: {$0.id == video.id}) {
//                trendingVideos.append(video)
//            }
//        }
//    }
    
}

