//
//  FullEpisodeView.swift
//  Vastly
//
//  Created by Casey Traina on 9/5/23.
//

import SwiftUI
import YouTubePlayerKit
import AVKit

struct FullEpisodeView: View {

    let video: Video
    
//    @State var publisherIsTapped = false
    @State var youtubePlayer: YouTubePlayer?
    
//    let player = YouTubePlayer(
//        source: .url("https://youtube.com/watch?v=psL_5RIBqnY"))
    
    @State var title: String?
    @State var publisherIsTapped: Bool = false

    var body: some View {
        
        ZStack {
            GeometryReader { geo in
                ZStack {
                    Color("BackgroundColor")
                        .ignoresSafeArea()
                    VStack {

                        
                        if let player = youtubePlayer {
                            YouTubePlayerView(
                                player,
                                placeholderOverlay: {
                                    VideoLoadingView()
                                        .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                                }
                            )
                            .shadow(color: .accentColor, radius: 5)
                            .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                            .onAppear {
                                player.play()
                                //                        title = player.
                                Task {
                                    do {
                                        title = try await player.getInformation().videoData.title
                                        print(title)
                                    } catch {
                                        print("Error getting video details: \(error)")
                                    }
                                }
                            }
                            .onDisappear {
                                player.pause()
                            }
                        } else {
                            VideoLoadingView()
                                .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                        }

                    }
                }
                .onAppear {
                    youtubePlayer = YouTubePlayer (source: .url(video.youtubeURL!))
                }
            }
            
            if publisherIsTapped {
                AuthorProfileView(author: video.author, publisherIsTapped: $publisherIsTapped)
//                            .frame(width: screenSize.width, height: screenSize.height)
//                            .transition(.opacity)
//                            .animation(.easeOut, value: publisherIsTapped)
            }
        } // Z
        
        
        
        
    } // body

}
