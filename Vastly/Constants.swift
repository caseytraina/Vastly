//
//  Constants.swift
//  Vastly
//
//  Created by Casey Traina on 5/10/23.
//

import Foundation
import SwiftUI
import AVKit

let screenSize: CGRect = UIScreen.main.bounds

let VIDEO_WIDTH = screenSize.width
let VIDEO_HEIGHT = screenSize.width * (9/16)

let IMAGEKIT_ENDPOINT = "https://ik.imagekit.io/4ni2tyc01/Firebase/"

let PUBLIC_KEY = "public_t9txC8byE5HU/lmM06QRbNpw7CU="

let EMPTY_VIDEO = Video(
    id: UUID().uuidString,
    title: "Unknown Source",
    author: EMPTY_AUTHOR,
    bio: "Oops — there's an issue on our end!",
    date: "Unknown",
    channels: ["No Channel"],
    url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/dash/ForBiggerMeltdownsVideo.mp4")!,
    youtubeURL: "")

//    player: AVPlayerItem(url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/dash/ForBiggerMeltdownsVideo.mp4")!))

let EXAMPLE_VIDEO = Video(
    id: UUID().uuidString,
    title: "3 Reasons AI Would Turn Against Humans",
    author: EXAMPLE_AUTHOR,
    bio: "Artificial intelligence safety expert Eliezer Yudkowsky discusses the dangers that come with future technology advancements.",
    date: "Jun 2023",
    channels: ["AI"],
    url: URL(string: "https://ik.imagekit.io/4ni2tyc01/Firebase/AI/3%20Reasons%20AI%20Would%20Turn%20Against%20Humans.mp4?tr=f-webm")!,
    youtubeURL: "https://www.youtube.com/watch?v=GYkq9Rgoj8E"
)

//    player: AVPlayerItem(url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/dash/ForBiggerMeltdownsVideo.mp4")!))




let EMPTY_UNPROCESSED_VIDEO = UnprocessedVideo(
    id: UUID().uuidString,
    title: "Unknown Source",
    author: "Missing Video!",
    bio: "Oops — there's an issue on our end!",
    date: "",
    channels: ["No Channel"],
    location: "Business/Building Trust for Retail Investors.mp4",
    youtubeURL: "")

let EXAMPLE_AUTHOR = Author(
    id: UUID(),
    text_id: "Y Combinator",
    name: "Y Combinator",
    bio: "Y Combinator is a world-renowned startup accelerator that has helped launch some of the biggest tech companies in the world. Their podcast is a must-listen for anyone interested in entrepreneurship, tech, or just learning from the best.  Hosted by Michael Siebel, a partner at Y Combinator, the podcast features interviews with founders, investors, and other thought leaders. Each episode is packed with insights, advice, and inspiration.  If you're looking to learn from the best and be inspired to start your own business, then Y Combinator's podcast is the perfect resource for you.",
    fileName: URL(string: "https://firebasestorage.googleapis.com/v0/b/rizeo-40249.appspot.com/o/Author%20Logos%2FY%20Combinator.jpg?alt=media&token=d40ffe39-871a-475d-8e62-86a08dc7077b"),
    website: "https://www.ycombinator.com/blog/tag/podcast/",
    apple: "https://podcasts.apple.com/us/podcast/y-combinator/id1236907421",
    spotify: "https://open.spotify.com/show/1tgqafxZAB0Bjd8nkwVtE4")

let EMPTY_AUTHOR = Author(
    id: UUID(),
    text_id: "No Text ID",
    name: "No Author Found",
    bio: "Nothing to see here...",
    fileName: URL(string: "https://ik.imagekit.io/4ni2tyc01/noAuthorFound.png"),
    website: "",
    apple: "",
    spotify: "")


let EMPTY_VIDEO_ARRAY: [Video] = [EMPTY_VIDEO]

let PROGRESS_BAR_HEIGHT: CGFloat = 4.0

