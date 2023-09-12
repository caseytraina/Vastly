//
//  SingleVideoView.swift
//  Vastly
//
//  Created by Casey Traina on 7/31/23.
//

import SwiftUI
import CoreMedia

struct SingleVideoView: View {
    
    @EnvironmentObject private var authModel: AuthViewModel
    @EnvironmentObject var viewModel: VideoViewModel
    
    @State var channel: Channel = FOR_YOU_CHANNEL
    
    var video: Video
    
    @State private var playerProgress: Double = 0
    @State private var playerDuration: CMTime = CMTime()
    @State private var playerTime: CMTime = CMTime()
    
    @State private var timeObserverToken: Any?

    @State var active: Channel = FOR_YOU_CHANNEL
    
    @State var videoMode = true
    ///ik-thumbnail.jpg
    ///
    ///
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            LinearGradient(gradient: Gradient(colors: myGradient(channel_index: 0)), startPoint: .topLeading, endPoint: .bottom)
                .ignoresSafeArea()
            GeometryReader { geo in
                VStack(alignment: .leading) {
                    if let player = viewModel.playerManager?.getPlayer(for: video) {
                        FullscreenVideoPlayer(videoMode: $videoMode, video: video, activeChannel: $active)
                            .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                            .padding(0)
                            .environmentObject(viewModel)
                            .onAppear {
                                
                                
                                if let timeObserverToken = timeObserverToken {
                                    player.removeTimeObserver(timeObserverToken)
                                    self.timeObserverToken = nil
                                }
                                
                                player.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                                    DispatchQueue.main.async {
                                        let duration = player.currentItem?.asset.duration
                                        self.playerDuration = duration ?? CMTime(value: 0, timescale: 1000)
                                        
                                        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
                                            self.playerTime = time
                                            self.playerProgress = time.seconds / (duration?.seconds ?? 1.0)
                                        }
                                    }
                                }
                                
                                player.play()
                            }
                            .onDisappear {
                                if let timeObserverToken = timeObserverToken {
                                    player.removeTimeObserver(timeObserverToken)
                                    self.timeObserverToken = nil
                                }
                                player.pause()
                            }
                        ProgressBar(value: $playerProgress, activeChannel: $channel, video: video)
                            .frame(width: screenSize.width, height: PROGRESS_BAR_HEIGHT)
                            .padding(0)
                            .environmentObject(viewModel)
                    }
                    
                    HStack {
                        MyText(text: getInfo(field: .title), size: geo.size.width * 0.045, bold: true, alignment:
                                .leading, color: .white)
                        .lineLimit(3)
                        .truncationMode(.tail)
                        .frame(alignment: .leading)
                        Spacer()
                        Image(systemName: videoIsLiked() ? "heart.fill" : "heart")
                            .foregroundColor(videoIsLiked() ? .red : .white)
                            .font(.system(size: screenSize.width * 0.05, weight: .medium))
                            .padding()
                            .onTapGesture {
                                DispatchQueue.main.async {
                                    toggleLike()
                                }
                            }
                            .transition(.opacity)
                            .animation(.easeOut)
                    }
                    
                    HStack() {
                        MyText(text: getInfo(field: .author), size: geo.size.width * 0.04, bold: false, alignment: .leading, color: Color("AccentGray"))
                            .truncationMode(.tail)
                        .lineLimit(1)
                        Spacer()
                        MyText(text: getInfo(field: .date), size: geo.size.width * 0.04, bold: false, alignment: .leading, color: Color("AccentGray"))

                    }
                    .padding(.bottom)
                    
                    MyText(text: getInfo(field: .bio), size: geo.size.width * 0.04, bold: false, alignment: .leading, color: Color("AccentGray"))
                        .truncationMode(.tail)
                        .lineLimit(8)
                        .padding(.bottom, geo.size.height * 0.05)
                        
                    
                }
                .position(x: screenSize.width/2, y: screenSize.height/3)
            }
            
        }
    }
    
    enum Field {
        case channel, title, bio, author, date
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
            if let videos = user.liked_videos {
                return videos.contains(where: { $0 == video.title })

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
