//
//  VideoStructure.swift
//  Vastly
//
//  Created by Casey Traina on 5/9/23.
//

import Foundation
import AVKit
import SwiftUI
import Firebase
import MediaPlayer

// Videos are queried from Firebase as FirebaseData, then translated into UnprocessedVideos before being used as type Video.
// Read more about video querying in CatalogViewModel

struct FirebaseData: Codable {
    let title: String?
    let author: String?
    let bio: String?
    let location: String?
    let date: String?
    let channels: [String]?
    let youtubeURL: String?

    
    enum CodingKeys: String, CodingKey {
        case title
        case author
        case bio
        case location = "fileName"
        case date
        case channels = "channels"
        case youtubeURL
    }
}

struct NowPlayableStaticMetadata {
    
    let assetURL: URL                   // MPNowPlayingInfoPropertyAssetURL
    let mediaType: MPNowPlayingInfoMediaType
                                        // MPNowPlayingInfoPropertyMediaType
    let isLiveStream: Bool              // MPNowPlayingInfoPropertyIsLiveStream
    
    let title: String                   // MPMediaItemPropertyTitle
    let artist: String?                 // MPMediaItemPropertyArtist
    let artwork: MPMediaItemArtwork?    // MPMediaItemPropertyArtwork
    
    let albumArtist: String?            // MPMediaItemPropertyAlbumArtist
    let albumTitle: String?             // MPMediaItemPropertyAlbumTitle
    
}

struct NowPlayableDynamicMetadata {
    
    let rate: Float                     // MPNowPlayingInfoPropertyPlaybackRate
    let position: Float                 // MPNowPlayingInfoPropertyElapsedPlaybackTime
    let duration: Float                 // MPMediaItemPropertyPlaybackDuration
    
    let currentLanguageOptions: [MPNowPlayingInfoLanguageOption]
                                        // MPNowPlayingInfoPropertyCurrentLanguageOptions
    let availableLanguageOptionGroups: [MPNowPlayingInfoLanguageOptionGroup]
                                        // MPNowPlayingInfoPropertyAvailableLanguageOptions
    
}

struct UnprocessedVideo: Codable {
    let id: String
    let title: String
    let author: String
    let bio: String
    let date: String?
    let channels: [String]
    let location: String
    let youtubeURL: String?
    
    // This function turns a path to a URL of a cached and compressed video, connecting to our CDN imagekit which is a URL-based video and image delivery and transformation company.
    func getVideoURL() -> URL? {
        var allowedCharacters = CharacterSet.urlQueryAllowed
        allowedCharacters.insert("/")
        
        var fixedPath = self.location.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
        fixedPath = fixedPath.replacingOccurrences(of: "’", with: "%E2%80%99")
        
        let urlStringUnkept: String = IMAGEKIT_ENDPOINT + fixedPath + "?tr=f-auto"
        if let url = URL(string: urlStringUnkept) {
            return url
        } else {
            print("URL is invalid")
            return EMPTY_VIDEO.url
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case bio
        case location = "fileName"
        case date
        case channels = "channels"
        case youtubeURL
    }
    
}

struct Video: Identifiable, Equatable {
    static func == (lhs: Video, rhs: Video) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id: String
    let title: String
    let author: Author
    let bio: String
    let date: String?
    var channels: [String]
    var url: URL?
    var youtubeURL: String?
    
    func getThumbnail() -> URL? {
        var urlString = self.url?.absoluteString
        
        urlString = urlString?.replacingOccurrences(of: "?tr=f-auto", with: "/ik-thumbnail.jpg")
        
        return URL(string: urlString ?? "")
    }
    
    // This function turns a path to a URL of a cached and compressed video, connecting to our CDN imagekit which is a URL-based video and image delivery and transformation company.
    static func getVideoURL(from location: String) -> URL? {
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
    
    static func resultToVideo(id: String, data: Any, authors: [Author]) -> Video? {
        guard let dataDict = data as? [String: Any] else {
            return nil
        }
        
        let video = Video(
            id: id,
            title:  dataDict["title"] as? String ?? "No title found",
            author: authors.first(where: { $0.text_id == dataDict["author"] as? String ?? "" }) ?? EMPTY_AUTHOR,
            bio: dataDict["bio"] as? String ?? "",
            date: dataDict["date"] as? String ?? "", // assuming you meant "date" here
            channels: dataDict["channels"] as? [String] ?? [],
            url: Video.getVideoURL(from: dataDict["fileName"] as? String ?? ""),
            youtubeURL: dataDict["youtubeURL"] as? String)
        
        
        return video
    }
}

struct Author: Identifiable {
    let id: UUID
    let text_id: String?
    let name: String?
    let bio: String?
    let fileName: URL?
    let website: String?
    let apple: String?
    let spotify: String?
}

struct Channel: Identifiable, Hashable {
    let id: String
    let order: Int?
    let title: String
    let color: Color
    let isActive: Bool
}

struct Profile {
    let firstName: String?
    let lastName: String?
    let email: String?
    let phoneNumber: String?
    let interests: [String]?
    let likedVideos: [String]?
    let viewedVideos: [String]?
    
    func name() -> String? {
        return "\(firstName ?? "") \(lastName ?? "")"
    }
    
    func hasWatched(_ video: Video) async throws -> Bool {
        return try await hasWatched(video.id)
    }
    
    func hasWatched(_ id: String) async throws -> Bool {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(self.phoneNumber ?? self.email ?? "")
        let foundVideo = try await userRef.collection("viewedVideos").document(id).getDocument()
        return foundVideo.exists
    }
    
    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
        case email
        case phoneNumber
        case liked_videos
        case interests
        case viewed_videos
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}



extension Video {
    func isURLReachable() async -> Bool {
        guard let url = url else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        do {
            let (response, _) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
                print("\(httpResponse.statusCode): \(url)")
                return false
            } else {
                print("i think good?: \(url)")
                return true
            }
        } catch {
            return false
        }
    }
}
