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

// Videos are queried from Firebase as FirebaseData, then translated into UnprocessedVideos before being used as type Video.
// Read more about video querying in VideoViewModel

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

struct UnprocessedVideo: Codable {
    let id: String
    let title: String
    let author: String
    let bio: String
    let date: String?
    let channels: [String]
    let location: String
    let youtubeURL: String?
    
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

struct Video: Identifiable {
    let id: String
    let title: String
    let author: Author
    let bio: String
    let date: String?
    var channels: [String]
    var url: URL?
    var youtubeURL: String?
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
