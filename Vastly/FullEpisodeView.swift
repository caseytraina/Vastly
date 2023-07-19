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
//                        if let text = title {
//                        MyText(text: "Full Episode From:", size: geo.size.width * 0.05, bold: false, alignment: .leading, color: .white)
//                        MyText(text: "\(video.title)", size: geo.size.width * 0.05, bold: true, alignment: .leading, color: .white)

//                        }
                        
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
                        
//                        HStack {
//                            Button(action: {
//                                withAnimation {
//                                    publisherIsTapped = true
//                                }
//                            }, label: {
//
//
//                                HStack(alignment: .center) {
//                                    AsyncImage(url: video.author.fileName) { image in
//                                        image.resizable()
//                                    } placeholder: {
//                                        ZStack {
//                                            Color("BackgroundColor")
//                                            MyText(text: "?", size: geo.size.width * 0.05, bold: true, alignment: .center, color: .white)
//                                        }
//                                    }
//                                    .frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
//                                    .clipShape(RoundedRectangle(cornerRadius: 5)) // Clips the AsyncImage to a rounded
//                                    .padding(.leading)
//                                    //                                        .animation(.easeOut, value: activeChannel)
//                                    //                                        .transition(.opacity)
//
//                                    MyText(text: video.author.name ?? "Unknown Author", size: geo.size.width * 0.04, bold: true, alignment: .leading, color: .white)
//                                        .padding(0)
//                                        .lineLimit(2)
//                                    //                                            .animation(.easeOut, value: activeChannel)
//                                    //                                            .transition(.opacity)
//                                    Spacer()
//                                }
//                                .padding(.vertical)
//
//                            })
//
//                            Spacer()
//
//
//                        }
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

//
//
//struct FullEpisodeView_Previews: PreviewProvider {
//    static var previews: some View {
//        FullEpisodeView()
//    }
//}
