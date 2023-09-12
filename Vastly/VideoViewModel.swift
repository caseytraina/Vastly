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
        
    @Published var videos: [Channel: [Video]] = [:] {
        didSet {
            self.playerManager?.videos = self.videos
        }
    }
    @Published var channels: [Channel] = [FOR_YOU_CHANNEL]
    var authors: [Author] = []
    
    @Published var isProcessing: Bool = true {
        didSet {
            self.playerManager = VideoPlayerManager(videos: self.videos)
        }
    }
    
    var playerManager: VideoPlayerManager?
    
    var authModel: AuthViewModel
    
    init(authModel: AuthViewModel) {
        // Initialize player manager here.
        self.authModel = authModel
        
        Task {
            var myVideos: [Channel: [UnprocessedVideo]] = [:]

            do {
                
                await getChannels()
                print("Got channels.")
                
                await getAuthors()
                print("Got authors.")
                
//                await getVideos(in: FOR_YOU_CHANNEL)
                await generateForYou(max: 40)
                print("Processed videos.")
                
                await getVideos()
//                self.playerManager = VideoPlayerManager(videos: self.videos)
                
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
                
            } catch {
                print("Error getting videos: \(error)")
                DispatchQueue.main.async {
//                    self.playerManager = VideoPlayerManager(videos: self.videos)
                    self.isProcessing = false
                }
            }
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
    func getVideos() async { //in channel: Channel) async {
        
        var videosDict: [Channel : [UnprocessedVideo]] = [:]

        let db = Firestore.firestore()
        let storageRef = db.collection("videos")
        
        for channel in self.channels {
            
            do {
                let snapshot = try await storageRef.whereField("channels", arrayContains: channel.id).limit(to: 20).getDocuments()
                //            let snapshot = try await storageRef.getDocuments()
                
                for document in snapshot.documents {
                    let unfilteredVideo = try document.data(as: FirebaseData.self)
                    let id = document.documentID
                    let punctuation: Set<Character> = ["?", "@", "#", "%", "^", "*"]
                    
                    if !(authModel.current_user?.viewed_videos?.contains(where: {$0 == id}) ?? false) {
                        if var loc = unfilteredVideo.location {
                            
                            loc.removeAll(where: { punctuation.contains($0) })
                            let video = UnprocessedVideo(
                                id: id,
                                title: unfilteredVideo.title ?? "Unknown Title",
                                author: unfilteredVideo.author ?? "The author for this video cannot be found.",
                                bio: unfilteredVideo.bio ?? "The bio for this video cannot be found. Please look online for more information.",
                                date: unfilteredVideo.date,
                                channels: unfilteredVideo.channels ?? ["none"],
                                location: "\(loc)",
                                youtubeURL: unfilteredVideo.youtubeURL)
                            print(loc)
                            
                            //                        for channelItem in video.channels {
                            //                            if let channel = self.channels.first(where: {$0.id == channelItem}) {
                            if videosDict[channel] != nil {
                                videosDict[channel]!.append(video)
                            } else {
                                videosDict[channel] = [video]
                            }
                            //                            }
                            //                        }
                        }
                        
                    }
                }
            } catch {
                print("error with video: \(error)")
            }
            
        }
            
        await processUnprocessedVideos(unprocessedVideos: videosDict)
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
    
    // This function queries all of the channels from firebase, housing them in a local array to be used to apply to videos.
    func getChannels() async {
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
        
//        self.channels = reorderChannels(self.channels);
    }
    
    func reorderChannels(_ array: [Channel]) -> [Channel] {
        
        var result: [Channel] = []
        
        for i in 0..<array.count {
            if let channel = array.first(where: {$0.order == i}) {
                result.append(channel);
            }
        }
        
        return result
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
    func processUnprocessedVideos(unprocessedVideos: [Channel: [UnprocessedVideo]], foryou: Bool = false) async {
//        Task {
            do {
                let processedVideos = try await processVideos(videos: unprocessedVideos, foryou: foryou)
                DispatchQueue.main.async {
                    if foryou == true {
                        DispatchQueue.main.async {
                            
                            self.videos[FOR_YOU_CHANNEL] = Array(processedVideos.values.flatMap { $0 })
                        }
                    } else {
                        
                        for key in processedVideos.keys {
//                        if let channel {
                            if (self.videos[key] == nil) {
                                DispatchQueue.main.async {
                                    self.videos[key] = processedVideos[key]
                                }
                            } else {
                                for video in processedVideos[key]! {
                                    DispatchQueue.main.async {
                                        self.videos[key]?.append(video)
                                    }
                                }
                            }
                        }
//                        }
                    }
                }
            } catch {
                // handle error
                print("Error processing videos: \(error)")
                DispatchQueue.main.async {
//                    if (self.videos.keys.count == Channel.allCases.count) {
//                        self.videos[Channel.foryou] = self.getRandomVideos(maxCount: 40)
//                        self.generateForYou();
//                    if self.videos.keys.count == self.channels.count {
//                        self.playerManager?.updatePlayers(videos: self.videos)
//                        self.isProcessing = false
//                    }
//                    }
                }
            }
//        }
    }
    
    // This function turns a path to a URL of a cached and compressed video, connecting to our CDN imagekit which is a URL-based video and image delivery and transformation company.
    func getVideoURL(from location: String) -> URL? {

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
    func processVideos(videos: [Channel : [UnprocessedVideo]], foryou: Bool? = false) async throws -> [Channel: [Video]] {
        var processedVideos: [Channel: [Video]] = [:]
        var count = 0
        // loop through unprocessed
        for video in Array(videos.values.flatMap { $0 }) {
            do {
                // await used since getAVPlayer returns async.
                let player = getVideoURL(from: video.location)
                let processedVideo = Video(id: video.id, title: video.title, author: findAuthor(video), bio: video.bio, date: video.date, channels: video.channels, url: player, youtubeURL: video.youtubeURL)
                count += 1
                
                if foryou == true {
                    if processedVideos[FOR_YOU_CHANNEL] != nil {
                        processedVideos[FOR_YOU_CHANNEL]!.append(processedVideo)
                    } else {
                        processedVideos[FOR_YOU_CHANNEL] = [processedVideo]
                    }
                } else {
                    
                    for channelItem in processedVideo.channels {
                        if let channel = self.channels.first(where: {$0.id == channelItem}) {
                            if processedVideos[channel] != nil {
                                processedVideos[channel]!.append(processedVideo)
                            } else {
                                processedVideos[channel] = [processedVideo]
                            }
                        }
                    }
                }
                
            } catch {

                print("error processing video: \(error)")
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
            let newVideo = Video(id: video.id,
                                 title: video.title,
                                 author: video.author,
                                 bio: video.bio,
                                 date: video.date,
                                 channels: ["For You"],
                                 url: video.url,
                                 youtubeURL: video.youtubeURL)
            
            if !randomVideos.contains(where: { $0.id == newVideo.id }) {
                randomVideos.append(newVideo)
            }
        }
        
        return randomVideos.shuffled().shuffled()
    }
    
    func generateForYou(max: Int) async {
                
        var videosDict: [Channel : [UnprocessedVideo]] = [:]
        
        let db = Firestore.firestore()
        let storageRef = db.collection("videos")
        
        do {
            let snapshot = try await storageRef.getDocuments()
            var indices: [Int] = []
            for _ in 0..<max {
                
                let index = Int.random(in: 0..<snapshot.documents.count)
                
                if !indices.contains(index) {
                    indices.append(index)

                    let document = snapshot.documents[index];
                    do {
                        let unfilteredVideo = try document.data(as: FirebaseData.self)
                        let id = document.documentID
                        let punctuation: Set<Character> = ["?", "@", "#", "%", "^", "*"]
                        if !(authModel.current_user?.viewed_videos?.contains(where: {$0 == id}) ?? false) {
                            if var loc = unfilteredVideo.location {
                                loc.removeAll(where: { punctuation.contains($0) })
                                let video = UnprocessedVideo(
                                    id: id,
                                    title: unfilteredVideo.title ?? "Unknown Title",
                                    author: unfilteredVideo.author ?? "The author for this video cannot be found.",
                                    bio: unfilteredVideo.bio ?? "The bio for this video cannot be found. Please look online for more information.",
                                    date: unfilteredVideo.date,
                                    channels: unfilteredVideo.channels ?? ["none"],
                                    location: "\(loc)",
                                    youtubeURL: unfilteredVideo.youtubeURL)
                                print(loc)
                                
                                if videosDict[FOR_YOU_CHANNEL] != nil {
                                    videosDict[FOR_YOU_CHANNEL]!.append(video)
                                } else {
                                    videosDict[FOR_YOU_CHANNEL] = [video]
                                }
                            }
                        }
                    }
                }
            }

        } catch {
            print("Error getting for you videos.")
        }

        await processUnprocessedVideos(unprocessedVideos: videosDict, foryou: true)
        
    }
}

