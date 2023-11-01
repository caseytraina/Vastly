//
//  Storage.swift
//  Vastly
//
//  Created by Casey Traina on 5/10/23.
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

// import ImageKitIO

/*
 VideoViewModel is responsible for the querying and handling of video data in-app. VideoViewModel handles all video operations, except for the actual playing of the videos. That is controlled in VideoObserver.
 */

class VideoViewModel: ObservableObject {
    @Published var videos: [Channel: [Video]] = [:] {
        didSet {
            DispatchQueue.main.async {
                self.playerManager?.videos = self.videos
            }
        }
    }

    @Published var channels: [Channel] = [FOR_YOU_CHANNEL]
    var authors: [Author] = []
    
    @Published var isProcessing: Bool = true {
        didSet {
            self.playerManager = VideoPlayerManager(videos: self.videos)
        }
    }
    
    @Published var viewedVideosProcessing: Bool = true
    @Published var likedVideosProcessing: Bool = true

    @Published var viewed_videos: [Video] = []
    
    var playerManager: VideoPlayerManager?
    
    var authModel: AuthViewModel
    
    init(authModel: AuthViewModel) {
        // Initialize player manager here.
        self.authModel = authModel
        
        Task {
            await self.getChannels()
            print("Got channels.")
            
            await self.getAuthors()
            print("Got authors.")
            
            await self.generateShapedForYou(max: 10)
            // We do this at the end so we can analyze the liked and viewed videos
            print("INIT: got for you videos.")

            // For you page must have completed loading before letting user into the app
            DispatchQueue.main.async {
                self.isProcessing = false
            }
            
            await self.getVideos()
            print("Got videos.")
            
            print("Processed videos.")
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
    func getVideos() async { // in channel: Channel) async {
        var videosDict: [Channel: [UnprocessedVideo]] = [:]

        let db = Firestore.firestore()
        let storageRef = db.collection("videos")
        
        for channel in self.channels {
            await addVideosTo(channel)
        }
    }
    
    func getVideo(id: String) async -> Video? {
        let db = Firestore.firestore()
        let storageRef = db.collection("videos").document(id)
        
        do {
            let document = try await storageRef.getDocument()
            let unfilteredVideo = try document.data()
            let id = document.documentID
            let punctuation: Set<Character> = ["?", "@", "#", "%", "^", "*"]
                
            if !(self.authModel.current_user?.viewedVideos?.contains(where: { $0 == id }) ?? false) {
                
                let vid = resultToVideo(id: id, data: unfilteredVideo)
                
                return vid
            }
        } catch {
            print("error with video: \(error)")
        }
        return nil
    }
    
    func resultToVideo(id: String, data: Any) -> Video? {
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
    
    // This function queries all of the authors from firebase, housing them in a local array to be used to apply to videos.
    func getAuthors() async {
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
        
        for i in 0 ..< array.count {
            if let channel = array.first(where: { $0.order == i }) {
                result.append(channel)
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
        let snapshot = try await storageRef.getDocuments()
        return snapshot.documents
    }
    
    func addVideosTo(_ channel: Channel) async {
        if channel == FOR_YOU_CHANNEL {
            await self.generateShapedForYou(max: 10);
            return;
        } else {
            
            do {
                
                guard let currentUser = self.authModel.current_user else { return }
                let functions = Functions.functions()
                functions.httpsCallable("getUnviewedVideos").call(["userId": currentUser.phoneNumber ?? currentUser.email, "channelID" : channel.id]) { (result, error) in
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    }
                    
                    if let dataArray = result?.data as? [[String: [String: Any]]] {
                        // Retrieve the key and value for the first dictionary in the array
                        var newVideos: [Video] = []
                        for unfilteredVideo in dataArray {
                            let video = self.resultToVideo(id: unfilteredVideo.first?.key ?? UUID().uuidString, data: unfilteredVideo.first?.value)
                            
                            if let video {
                                newVideos.append(video)
                            }
                            
                        }
                        
                        if self.videos[channel] == nil {
                            DispatchQueue.main.async {
                                self.videos[channel] = newVideos
                            }
                        } else {
                            DispatchQueue.main.async {
                                for video in newVideos {
                                    self.videos[channel]?.append(video)
                                }
                            }
                        }
                    }
                }
            } catch {
                print("error with video: \(error)")
            }

        }
        
    }
    
    // This function turns a path to a URL of a cached and compressed video, connecting to our CDN imagekit which is a URL-based video and image delivery and transformation company.
    func getVideoURL(from location: String) -> URL? {
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
  
    func getThumbnail(video: Video) -> URL? {
        var urlString = video.url?.absoluteString
        
        urlString = urlString?.replacingOccurrences(of: "?tr=f-auto", with: "/ik-thumbnail.jpg")
        
        return URL(string: urlString ?? "")
    }
    
    func fetchValueFromPlist(key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject]
        else {
            return nil
        }
        
        return dict[key] as? String
    }
    
    struct ShapedResponse: Codable {
        var ids: [String]
        var scores: [Double]
    }
    
    func generateShapedForYou(max: Int) async {
        
        let userId = self.authModel.current_user?.phoneNumber ?? self.authModel.current_user?.email ?? ""
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
            
            var finalVideos: [Video] = []
            
            for videoId in json.ids {
                do {
                    // this doesn't seem to work right when you do an `in` query
                    // preserve the order here as they will be ranked from shaped
                    
                    // the shaped model will handle filtering out videos
                    // which have been viewed already
                    let document = try await videosRef.document(videoId).getDocument()
                    let unfilteredVideo = try document.data()
                    let id = document.documentID
                    
                    let vid = resultToVideo(id: id, data: unfilteredVideo)
                    
                    if let vid {
                        finalVideos.append(vid)
                    }
                    
                } catch {
                    print("error looking up videos: \(error)")
                }
            }
            
            if self.videos[FOR_YOU_CHANNEL] == nil {
                DispatchQueue.main.async {
                    self.videos[FOR_YOU_CHANNEL] = finalVideos
                }
            } else {
                DispatchQueue.main.async {
                    for video in finalVideos {
                        self.videos[FOR_YOU_CHANNEL]?.append(video)
                    }
                }
            }

        } catch {
            print("error looking up shaped api: \(error)")
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
}
