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
    
    @Published var viewed_videos: [Video] = []
    
    var playerManager: VideoPlayerManager?
    
    var authModel: AuthViewModel
    
    init(authModel: AuthViewModel) {
        // Initialize player manager here.
        self.authModel = authModel
        
        Task {
            
            await getChannels()
            print("Got channels.")
            
            await getAuthors()
            print("Got authors.")
            
            await getVideos()
            print("Got videos.")

            
            await generateShapedForYou(max: 20)
            // We do this at the end so we can analyze the liked and viewed videos
//            await generateForYou(max: 40)
            print("INIT: got for you videos.")

            // For you page must have completed loading before letting user into the app
            DispatchQueue.main.async {
                self.isProcessing = false
            }
            print("Processed videos.")
            
            await fetchViewedVideos()
            print("INIT: got viewed videos.")

            await fetchLikedVideos()
            print("INIT: got liked videos.")
            
            
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
                    
                    if !(authModel.current_user?.viewedVideos?.contains(where: {$0 == id}) ?? false) {
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
    
    func getVideo(id: String) async -> Video? { //in channel: Channel) async {
        
//        var videosDict: [Channel : [UnprocessedVideo]] = [:]

        let db = Firestore.firestore()
        let storageRef = db.collection("videos").document(id)
        
        var result: Video? = nil
        
        for channel in self.channels {
            
            do {
                let document = try await storageRef.getDocument()
                //            let snapshot = try await storageRef.getDocuments()
                
//                for document in snapshot.documents {
                    let unfilteredVideo = try document.data(as: FirebaseData.self)
                    let id = document.documentID
                    let punctuation: Set<Character> = ["?", "@", "#", "%", "^", "*"]
                    
                    if !(authModel.current_user?.viewedVideos?.contains(where: {$0 == id}) ?? false) {
                        if var loc = unfilteredVideo.location {
                            
                            loc.removeAll(where: { punctuation.contains($0) })
                            let video = Video(id: id,
                                  title: unfilteredVideo.title ?? "Unknown Title",
                                  author: self.authors.first(where: { $0.text_id == unfilteredVideo.author?.trimmingCharacters(in: .whitespacesAndNewlines)}) ?? EMPTY_AUTHOR,
                                  bio: unfilteredVideo.bio ?? "The bio for this video cannot be found. Please look online for more information.",
                                  date: unfilteredVideo.date,
                                  channels: unfilteredVideo.channels ?? ["none"],
                                  url: getVideoURL(from: unfilteredVideo.location ?? ""),
                                  youtubeURL: unfilteredVideo.youtubeURL)
                            
                            return video

                        }
                        
                    }
//                }
            } catch {
                print("error with video: \(error)")
            }
            
        }
        return nil
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
        
//        print(urlString)
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
        // foryou is ordered, don't want to shuffle it up
        if foryou != true {
            for channel in processedVideos.keys {
                processedVideos[channel] = processedVideos[channel]?.shuffled().shuffled()
            }
        }
        
        return processedVideos
    }
  
      func getThumbnail(video: Video) -> URL? {
        
        var urlString = video.url?.absoluteString
        
        urlString = urlString?.replacingOccurrences(of: "?tr=f-auto", with: "/ik-thumbnail.jpg")
        
        return URL(string: urlString ?? "")
    }
    
    
    // Approach
    // Generate a list of users top channels (based on likes and watches)
    //    return top videos (sorted by likes and views) in those channels
    // If there isn't enough videos to reach the max then we backfill with random
    func generateForYouNew(max: Int) async {
        var videosDict: [Channel : [UnprocessedVideo]] = [:]
        var topChannels: [String : Int] = [:]
        let db = Firestore.firestore()

        let storageRef = db.collection("videos")
        let viewedRef = db.collection("users").document(self.authModel.current_user?.phoneNumber ?? self.authModel.current_user?.email ?? "").collection("viewedVideos")
        let likedRef = db.collection("users").document(self.authModel.current_user?.phoneNumber ?? self.authModel.current_user?.email ?? "").collection("likedVideos")
        
        
        
        
        do {
            let viewedSnapshot = try await viewedRef
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            let likedSnapshot = try await likedRef
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            var viewedCount = 0
            var likedCount = 0
            
            for document in likedSnapshot.documents {
                if likedCount >= 10 {
                    break;
                }
                if let video = await getVideo(id: document.documentID) {
                    for channel in video.channels {
                        if !topChannels.keys.contains(channel) {
                            topChannels[channel] = 1
                        } else {
                            topChannels[channel]! += 1
                        }
                    }
                    likedCount += 1
                } else {
                    print("Could not find video for given ID: \(document.documentID)")
                }
            }
            
            for document in viewedSnapshot.documents {
                if viewedCount >= 10 {
                    break;
                }
                if let video = await getVideo(id: document.documentID) {
                    for channel in video.channels {
                        if !topChannels.keys.contains(channel) {
                            topChannels[channel] = 1
                        } else {
                            topChannels[channel]! += 1
                        }
                    }
                    viewedCount += 1
                } else {
                    print("Could not find video for given ID: \(document.documentID)")
                }
            }
            
//        } catch {
//            print("FOR YOU — There was an error querying videos: \(error)")
//        }
        

            

            // return videos in the top channels
            print("FOR YOU: Fetching most liked videos in", topChannels.keys)
            
                let snapshot = try await storageRef
                    .whereField("channels", arrayContains: topChannels.keys)
    //                .whereField("id", notIn: self.viewed_videos.map { v in v.id }) ---- *REMOVED* 10 ITEM LIMIT ON NOT-IN
                    .order(by: "id")
                    .limit(to: max)
                    .order(by: "likedCount", descending: true)
                    .order(by: "viewedCount", descending: true)
                    .getDocuments()
                
                print("FOR YOU: Found", snapshot.documents.count)
                
                for document in snapshot.documents {
                    
                    if !viewedSnapshot.documents.contains(where: { $0.documentID == document.documentID }) {
                        let unfilteredVideo = try document.data(as: FirebaseData.self)
                        let id = document.documentID
                        let punctuation: Set<Character> = ["?", "@", "#", "%", "^", "*"]
                        
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
            
            } catch {
                print("Error getting for you videos: \(error)")
            }
            let missingVideos = max - (videosDict[FOR_YOU_CHANNEL]?.count ?? 0)
            if missingVideos == 0 {
                await processUnprocessedVideos(unprocessedVideos: videosDict, foryou: true)
            } else {
                print("FOR YOU: Backfilling with", missingVideos, "random videos")
                await generateRandomForYou(max: missingVideos, existingVideosDict: videosDict)
            }
        
        
        if topChannels.keys.isEmpty {
            // If there is no user activity then we just return random for now
            return await generateRandomForYou(max: max)
        }
        
    }
    
    func fetchValueFromPlist(key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
            return nil
        }
        
        return dict[key] as? String
    }
    
    struct ShapedResponse: Codable {
        var ids: [String]
        var scores: [Double]
    }
    
    func generateShapedForYou(max: Int) async {
        var videosDict: [Channel : [UnprocessedVideo]] = [:]
        
        let userId = self.authModel.current_user?.phoneNumber ?? self.authModel.current_user?.email ?? ""
        var rankURL = URLComponents(string: "https://api.prod.shaped.ai/v1/models/viewed_video_recommendations_2/rank")!
        let queryItems = [
            URLQueryItem(name: "user_id", value: userId),
            URLQueryItem(name: "limit", value: String(max)),
            URLQueryItem(name: "return_metadata", value: "false")
        ]
        rankURL.queryItems = queryItems
        var request = URLRequest(url: rankURL.url!)
        
        let key: String = fetchValueFromPlist(key: "SHAPED_API_KEY") ?? ""

        request.addValue(key,
                         forHTTPHeaderField: "x-api-key")
        
        let urlSession = URLSession.shared
        let (data, _) = try! await urlSession.data(for: request)
        do {
            let json = try JSONDecoder().decode(ShapedResponse.self, from: data)
            let db = Firestore.firestore()
            let videosRef = db.collection("videos")
            do {
                for videoId in json.ids {
                    // this doesn't seem to work right when you do an `in` query
                    // preserve the order here as they will be ranked from shaped
                    let document = try await videosRef.document(videoId).getDocument()
                    if !self.viewed_videos.map({ $0.id }).contains(where: {$0 == document.documentID}) {
                        let unfilteredVideo = try document.data(as: FirebaseData.self)
                        let id = document.documentID
                        let punctuation: Set<Character> = ["?", "@", "#", "%", "^", "*"]
                        
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
                            
                            if videosDict[FOR_YOU_CHANNEL] != nil {
                                if !(videosDict[FOR_YOU_CHANNEL]?.contains(where: {$0.id == video.id}))! {
                                    videosDict[FOR_YOU_CHANNEL]!.append(video)
                                }
                            } else {
                                videosDict[FOR_YOU_CHANNEL] = [video]
                            }
                        }
                    }
                }
            } catch {
                print("error looking up videos")
            }
        } catch {
            print("error looking up shaped api")
        }
        
        await processUnprocessedVideos(unprocessedVideos: videosDict, foryou: true)
    }
    
    // *NEW* Approach
    // Generate a list of users top channels (based on likes and watches) and assign a frequency value to each
    // return (not yet, but soon top) videos (*temp removed* sorted by likes and views) in those channels and add a proportionate number of videos based on freq value and max
    // If there isn't enough videos to reach the max then we backfill with random
    func generateForYou(max: Int) async {
        var videosDict: [Channel : [UnprocessedVideo]] = [:]
//        var topChannels: [String] = []
        var topChannels: [String : Int] = [:]

        for likedVideo in self.authModel.liked_videos.prefix(10) {
            for channel in likedVideo.channels {
                if !topChannels.keys.contains(channel) {
                    topChannels[channel] = 2
                } else {
                    topChannels[channel]! += 2
                }
            }
        }
        
        for viewedVideo in self.viewed_videos.prefix(10) {
            for channel in viewedVideo.channels {
                if !topChannels.keys.contains(channel) {
                    topChannels[channel] = 1
                } else {
                    topChannels[channel]! += 1
                }
            }
        }
        
        if topChannels.keys.count == 0 {
            // If there is no user activity then we just return random for now
            return await generateRandomForYou(max: max)
        }
        let sum = topChannels.values.reduce(0, +)

        
        for channel in topChannels.keys {
            let operand: Double = Double(topChannels[channel]!)/Double(sum)
            topChannels[channel]! = Int( operand * Double(max))
        }
        
        let db = Firestore.firestore()
        let storageRef = db.collection("videos")
        // return videos in the top channels
        print("FOR YOU: Fetching most liked videos in", topChannels)
        
        for channel in topChannels.keys {
            let channelMax = topChannels[channel]
            do {
                let snapshot = try await storageRef
                    .whereField("channels", arrayContains: channel as NSString)
//                    .order(by: "id")
                    .limit(to: max) // limit videos to channelMax when appending
//                    .order(by: "likedCount", descending: true) // Uncomment to sort by popularity. Must first add likedCount & viewedCount to all videos.
//                    .order(by: "viewedCount", descending: true)
                    .getDocuments()
                
                print("FOR YOU: \(channel) looking for \(channelMax) and Found", snapshot.documents.count)
                var added = 0
                
                for document in snapshot.documents {
                    
                    if !self.viewed_videos.map({ $0.id }).contains(where: {$0 == document.documentID}) {
                        let unfilteredVideo = try document.data(as: FirebaseData.self)
                        let id = document.documentID
                        let punctuation: Set<Character> = ["?", "@", "#", "%", "^", "*"]
                        
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

                            if added >= channelMax! {
                                break;
                            } else {
                                if videosDict[FOR_YOU_CHANNEL] != nil {
                                    if !(videosDict[FOR_YOU_CHANNEL]?.contains(where: {$0.id == video.id}))! {
                                        videosDict[FOR_YOU_CHANNEL]!.append(video)
                                    }
                                } else {
                                    videosDict[FOR_YOU_CHANNEL] = [video]
                                }
                                added += 1
                            }
                        }
                    }
                }
                print("FOR YOU: added \(added) videos to \(channel)")

            } catch {
                print("Error getting for you videos: \(error) in \(channel)")

            }
            
        }

        
        let missingVideos = max - (videosDict[FOR_YOU_CHANNEL]?.count ?? 0)
        if missingVideos == 0 {
            await processUnprocessedVideos(unprocessedVideos: videosDict, foryou: true)
        } else {
            print("FOR YOU: Backfilling with", missingVideos, "random videos")
            await generateRandomForYou(max: missingVideos, existingVideosDict: videosDict)
        }
        
        
        
    }
    
    func generateRandomForYou(max: Int, existingVideosDict: [Channel : [UnprocessedVideo]] = [:]) async {
        var videosDict = existingVideosDict
        
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
                        if !(authModel.current_user?.viewedVideos?.contains(where: {$0 == id}) ?? false) {
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
    
    func fetchViewedVideos() async {
        if let viewed_videos = self.authModel.current_user?.viewedVideos {
            
            let db = Firestore.firestore()
            let ref = db.collection("videos")
            
            for id in viewed_videos {
                do {
                    let doc = try await ref.document(id).getDocument()
                    if doc.exists {
                        
                        print("Doc Found for \(id)")
                        
                        let data = try doc.data()
                        
                        let vid = UnprocessedVideo(
                            id: doc.documentID,
                            title: data?["title"] as? String ?? "",
                            author: data?["author"] as? String ?? "",
                            bio: data?["bio"] as? String ?? "",
                            date: data?["date"] as? String ?? "",
                            channels: data?["channels"] as? [String] ?? [],
                            location: data?["fileName"] as? String ?? "",
                            youtubeURL: data?["youtubeURL"] as? String ?? "")
                        
                        let video = Video(
                            id: vid.id,
                            title: vid.title,
                            author: self.findAuthor(vid),
                            bio: vid.bio,
                            date: vid.date,
                            channels: vid.channels,
                            url: self.getVideoURL(from: vid.location),
                            youtubeURL: vid.youtubeURL)
                        
                        if !self.viewed_videos.contains(where: {$0.id == video.id}) {
                            self.viewed_videos.append(video)
                        }
                        
                    } else {
                        print("Doc not found for \(id)")
                    }
                    
                } catch {
                    print("Error getting viewing history: \(error)")
                }
            }
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
                        
                        let data = try doc.data()
                        
                        let vid = UnprocessedVideo(
                            id: doc.documentID,
                            title: data?["title"] as? String ?? "",
                            author: data?["author"] as? String ?? "",
                            bio: data?["bio"] as? String ?? "",
                            date: data?["date"] as? String ?? "",
                            channels: data?["channels"] as? [String] ?? [],
                            location: data?["fileName"] as? String ?? "",
                            youtubeURL: data?["youtubeURL"] as? String ?? "")
                        
                        let video = Video(
                            id: vid.id,
                            title: vid.title,
                            author: self.findAuthor(vid),
                            bio: vid.bio,
                            date: vid.date,
                            channels: vid.channels,
                            url: self.getVideoURL(from: vid.location),
                            youtubeURL: vid.youtubeURL)
                        
                        if !self.authModel.liked_videos.contains(where: {$0.id == video.id}) {
                            self.authModel.liked_videos.append(video)
                        }
                        
                    } else {
                        print("Doc not found for \(id)")
                    }
                    
                } catch {
                    print("Error getting viewing history: \(error)")
                }
            }
        }
    }
    
    
}

