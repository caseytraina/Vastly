//
//  SingleVideoView.swift
//  Vastly
//
//  Created by Casey Traina on 7/31/23.
//

import SwiftUI
import CoreMedia
import AVKit

struct SingleVideoView: View {
    
    @EnvironmentObject private var authModel: AuthViewModel
    @EnvironmentObject var viewModel: VideoViewModel
    
    @State var channel: Channel = FOR_YOU_CHANNEL
    
    @Binding var isActive: Bool
    
    var video: Video
    
    @State private var playerProgress: Double = 0
    @State private var playerDuration: CMTime = CMTime()
    @State private var playerTime: CMTime = CMTime()
    
    @State private var timeObserverToken: Any?

    @State var active: Channel = FOR_YOU_CHANNEL
    
    @State var videoMode = true
    
    @State var isPlaying = true
    @State var publisherIsTapped = false
    @State var bioExpanded = false

    @State var shareURL: URL?
    ///ik-thumbnail.jpg
    ///
    ///
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
//            LinearGradient(gradient: Gradient(colors: myGradient(channel_index: 0)), startPoint: .topLeading, endPoint: .bottom)
//                .ignoresSafeArea()
            GeometryReader { geo in
                VStack(alignment: .leading) {

                    HStack(alignment: .center) {
                        MyText(text: video.title, size: 20, bold: true, alignment: .leading, color: .gray)
                            .brightness(0.4)
                            .lineLimit(2)
                        Spacer()
                        Toggle(isOn: $videoMode) {
                            
                        }
                        .toggleStyle(AudioToggleStyle(color: channel.color))
                        .padding(10)
                        .frame(width: screenSize.width * 0.1)
                    }
                    .padding(.horizontal)
                    
                    ZStack {
                        
                        ZStack {
                            FullscreenVideoPlayer(videoMode: $videoMode, video: video, activeChannel: $channel)
                                .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                                .padding(0)
                                .environmentObject(viewModel)

                            if !videoMode {
                                AudioOverlay(author: video.author, video: video, playing: $isPlaying)
                                    .environmentObject(viewModel)
                            }
                            if !isPlaying {
                                Image(systemName: "play.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: screenSize.width * 0.15, weight: .light))
                                    .shadow(radius: 2.0)
                                    .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                            }
                        }
                            
                        ProgressBar(value: $playerProgress, activeChannel: $channel, video: video, isPlaying: $isPlaying)
                            .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT+20)
                            .padding(0)
                            .environmentObject(viewModel)
                    } // end vstack
                    .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT+20)
            
                
                    VStack(alignment: .center) {
                        
                        HStack(alignment: .top) {
                            MyText(text: playerTime.asString, size: 12, bold: false, alignment: .leading, color: .gray)
                                .lineLimit(1)
                                .brightness(0.4)
                            
                            Spacer()
                            MyText(text: playerDuration.asString, size: 12, bold: false, alignment: .leading, color: .gray)
                                .lineLimit(1)
                                .brightness(0.4)
                        } // end hstack
                        .frame(width: PROGRESS_BAR_WIDTH)
                        //                .frame(width: geoWidth)
                        
                        HStack {
                            
                            
                            Button(action: {
                                withAnimation {
                                    publisherIsTapped = true
                                }
                            }, label: {
                                
                                
                                HStack(alignment: .center) {
                                    AsyncImage(url: video.author.fileName) { image in
                                        image.resizable()
                                    } placeholder: {
                                        ZStack {
                                            Color("BackgroundColor")
                                        }
                                    }
                                    .frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
                                    .clipShape(RoundedRectangle(cornerRadius: 5)) // Clips the AsyncImage to a rounded
                                    //                                        .animation(.easeOut, value: activeChannel)
                                    //                                        .transition(.opacity)
                                    VStack(alignment: .leading) {
                                        MyText(text: video.author.name ?? "Unknown Author", size: 16, bold: true, alignment: .leading, color: .gray)
                                            .lineLimit(1)
                                            .brightness(0.4)
                                        MyText(text: video.date ?? "", size: 12, bold: false, alignment: .leading, color: .gray)
                                            .lineLimit(1)
                                            .brightness(0.4)
                                        
                                    }
                                    //                                            .animation(.easeOut, value: activeChannel)
                                    //                                            .transition(.opacity)
                                    Spacer()
                                    
                                }
                                
                            })
                            
                            Spacer()
                        } // end hstack
                        
                        //                .frame(width: geoWidth)
                        //            .padding(.horizontal, 15)
                        
                        VStack(alignment: .leading) {
                            SeeMoreText(text: video.bio, size: 16, bold: false, alignment: .leading, color: .gray, expanded: $bioExpanded)
                            //                        .truncationMode(.tail)
                                .brightness(0.4)
                                .onTapGesture {
                                    withAnimation {
                                        bioExpanded.toggle()
                                    }
                                }
                                .padding(.vertical, 5)
                            
                            HStack (alignment: .center) {
                                if let _ = video.youtubeURL {
                                    
                                    FullEpisodeButton(video: video, isPlaying: $isPlaying)
                                    //                                .frame(maxWidth: geoWidth * 0.5, maxHeight: geoHeight * 0.075)
                                        .padding(.trailing, 5)
                                    
                                }
                                
                                Button(action: {
                                    DispatchQueue.main.async {
                                        if videoIsLiked() {
                                            isActive.toggle()
                                            viewModel.playerManager?.pause(for: video)

                                        }
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                        toggleLike()
                                    }
                                }, label: {
                                    if let image = UIImage(named: videoIsLiked() ? "bookmark-fill" : "bookmark") {
                                        Image(uiImage: image)
                                            .renderingMode(.template)
                                            .foregroundColor(videoIsLiked() ? .white : .white)
                                            .font(.system(size: 18, weight: .medium))
                                            .frame(width: 24, height: 24)
                                            .transition(.opacity)
                                            .animation(.easeOut, value: videoIsLiked())
                                            .padding(5)
                                            .background(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .foregroundStyle(.gray)
                                                    .opacity(0.25)
                                            )
                                    }
                                })
                                .padding(.trailing, 5)
                                
                                
                                if let shareURL {
                                    ShareLink(item: shareURL) {
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundColor(.white)
                                            .font(.system(size: 18, weight: .medium))
                                            .frame(width: 24, height: 24)
                                            .padding(5)
                                            .background(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .foregroundStyle(.gray)
                                                    .opacity(0.25)
                                            )
                                    }
                                    .padding(.trailing, 5)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            //                    .padding(.horizontal, 15)
                            
                            Spacer()
                            
                        } // end vstack
                        
                        
                    } // end vstack
//                    .position(x: screenSize.width/2, y: screenSize.height/3)
                    .onChange(of: isPlaying) { newPlaying in
                        if newPlaying {
                            viewModel.playerManager?.play(for: video)
//                            viewModel.playerManager?.getPlayer(for: video).play()
                        } else {
                            viewModel.playerManager?.pause(for: video)
                        }
                    }
                }
            }
            
        }
        .onAppear {
//            isPlaying = false
            viewModel.playerManager?.play(for: video)
//            viewModel.playerManager?.getPlayer(for: video).play()
            shareURL = videoShareURL(video)
        }
        .onDisappear {
            viewModel.playerManager?.pause(for: video)
        }
    }
    
    enum Field {
        case channel, title, bio, author, date
    }
    
    private func videoShareURL(_ video: Video) -> URL {
        let string = "vastlyapp://open-video?id=\(String(video.id.replacingOccurrences(of: " ", with: "%20")))"
        return URL(string: string) ?? EMPTY_VIDEO.url!
    }
    
    private func getInfo(field: Field) -> String {
        switch field {
        case .channel:
            return video.channels[0]
        case .title:
            return video.title
        case .author:
            return video.author.name ?? ""
        case .bio:
            return video.bio
        case .date:
            return video.date ?? ""
        }
            
    }
    
    private func videoIsLiked() -> Bool {
        if let user = authModel.current_user {
            if let videos = user.likedVideos {
                return videos.contains(where: { $0 == video.id })
            }
        }
        return false
    }
    
    private func toggleLike() {
        if let user = authModel.current_user {
            if videoIsLiked() {
                Task {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    await authModel.removeLikeFrom(video)
                }
            } else {
                Task {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    await authModel.addLikeTo(video)
                }
                
            }
        }
    }
    
    private func observePlayer(to player: AVQueuePlayer) {
                
        if let item = player.currentItem {
            
            //        DispatchQueue.global(qos: .userInitiated).async {
            print("Attached observer to \(item)")
            
            item.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                DispatchQueue.main.async {
                    let duration = player.items().last?.asset.duration
                    self.playerDuration = duration ?? CMTime(value: 0, timescale: 1000)
                    
                    timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1000), queue: .main) { time in
                        self.playerTime = time
                        self.playerProgress = time.seconds / (duration?.seconds ?? 1.0)
                    }
                }
            }
            
            print("Started Observing Video")
//            
//            if let endObserverToken = endObserverToken {
//                NotificationCenter.default.removeObserver(endObserverToken)
//                self.endObserverToken = nil
//            }
//
//            endObserverToken = NotificationCenter.default.addObserver(
//                forName: .AVPlayerItemDidPlayToEndTime,
//                object: item,
//                queue: .main
//            ) { _ in
//                
//                if item == player.items().last {
//                    //            if player.currentItem == player.items().last {
//                    recent_change = true
//                    playSound()
//                    videoCompleted(for: getVideo(current_playing), with: authModel.user, profile: authModel.current_user)
//                    print("VIDEO ENDED: \(player.items().last)")
//                    item.seek(to: CMTime.zero)
//                    
//                    player.pause()
//                    current_playing += 1;
//                    //            }
//                }
//            }
        }
    }
    
    
    private func myGradient(channel_index: Int) -> [Color] {
        
//        let background = Color(red: 18.0/255, green: 18.0/255, blue: 18.0/255)
        let background = Color(red: 5/255, green: 5/255, blue: 5/255)

        let channel_color = viewModel.channels[channel_index].color.opacity(0.8)

//        let purple = Color(red: 0.3803921568627451, green: 0.058823529411764705, blue: 0.4980392156862745)
        var gradient: [Color] = [channel_color]
        
        for _ in 0..<5 {
            gradient.append(background)
        }
        return gradient
    }
    
    
    
}

//struct SingleVideoView_Previews: PreviewProvider {
//    static var previews: some View {
//        SingleVideoView()
//    }
//}
