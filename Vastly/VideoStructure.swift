//
//  VideoStructure.swift
//  Vastly
//
//  Created by Casey Traina on 5/9/23.
//

import Foundation
import AVKit
import SwiftUI

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
    let likedVideos: [String]?
    let interests: [String]?
    let viewed_videos: [String]?
    
    func name() -> String? {
        return "\(firstName ?? "") \(lastName ?? "")"
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

//enum Channel: String, CaseIterable {
//    case foryou = "For You"
//
//    case bizNews = "Daily Biz News"
//    case startups = "Entrepreneurship"
//    case ai = "AI"
//    case ventureCapital = "Venture Capital"
//    case bigTech = "Big Tech"
//    case finance = "Finance & Investing"
//    case leadership = "Leadership"
//    case stanford = "View From The Top"
//    case global = "World Economic Forum"
//    case space = "Space"
//
//    var title: String {
//        switch self {
//        case .foryou: return "For You"
//        case .bizNews: return "Biz News"
//        case .startups: return "Startups"
//        case .ai: return "AI"
//        case .ventureCapital: return "VC"
//        case .bigTech: return "Big Tech"
//        case .finance: return "Finance"
//        case .leadership: return "Leadership"
//        case .stanford: return "Stanford"
//        case .global: return "Global"
//        case .space: return "Space"
//        }
//    }
//
//    var imageName: String {
//        switch self {
//        case .foryou:
//            return "foryou"
//        case .startups:
//            return "entrepreneurship"
//        case .finance:
//            return "investingfinance"
//        case .stanford:
//            return "viewfromthetop"
//        case .global:
//            return "worldeconomicforum"
//        case .ventureCapital:
//            return "ventureCapital"
//        case .bizNews:
//            return "dailyBiz"
//        case .ai:
//            return "ai"
//        case .bigTech:
//            return "bigTech"
//        case .leadership:
//            return "leadership"
//        default:
//            return ""
//        }
//    }
//
//    var color: Color {
//        switch self {
//        case .foryou:
//            return Color(red: 0.45, green: 0.31, blue: 1);
//        case .startups:
//            return Color(red: 0.18, green: 0.59, blue: 0.69);
//        case .bigTech:
//            return Color(red: 0.31, green: 0.46, blue: 1);
//        case .stanford:
//            return Color(red: 0.31, green: 0.83, blue: 1);
//        case .global:
//            return Color(red: 0.31, green: 1, blue: 0.71);
//        case .leadership:
//            return Color(red: 1, green: 0.31, blue: 0.31);
//        case .finance:
//            return Color(red: 1, green: 0.81, blue: 0.31);
//        case .ventureCapital:
//            return Color(red: 1, green: 0.43, blue: 0.31);
//        case .bizNews:
//            return Color(red: 0, green: 0.61, blue: 0.46);
//        case .ai:
//            return Color(red: 0.71, green: 0.34, blue: 0);
//        case .space:
//            return Color(red: 0.45, green: 0.31, blue: 1);
//        }
//    }
    
    
    
    //    case bizNews = "Biz News"
    //    case startups = "Startups"
    //    case ai = "AI"
    //    case ventureCapital = "VC"
    //    case bigTech = "Big Tech"
    //    case finance = "Finance"
    //    case leadership = "Leadership"
    //    case stanford = "Stanford"
    //    case global = "Global"
//    case allIn = "All-In"
//    case acquired = "Acquired"
//    case stanfordGSB = "Stanford"
//    case thisWeekStartups = "This Week In Startups"
//    case grahamWeaver = "Graham Weaver"
//    case netflix = "Netflix Co-founder Marc Randolph"
//    case morningBrew = "Morning Brew Daily"
//    case bestOneYet = "The Best One Yet"
//}


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
