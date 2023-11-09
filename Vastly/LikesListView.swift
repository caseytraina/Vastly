//
//  LikesListView.swift
//  Vastly
//
//  Created by Casey Traina on 7/31/23.
//

import SwiftUI

struct LikesListView: View {
    
    @EnvironmentObject private var authModel: AuthViewModel
    @EnvironmentObject var videoViewModel: VideoViewModel
    
    @State var isAnimating = false
    @State var processed = false

    
    @Binding var isPlaying: Bool
    
    @State var dummyChannel = FOR_YOU_CHANNEL
    
    @State var dummyPublisher = false
    
    @State var dragOffset = 0.0
    @State var cur = 0
    
    @State var isLinkActive = false
    
    @State var current_video = EMPTY_VIDEO
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            LinearGradient(gradient: Gradient(colors: myGradient(channel_index: 0)), startPoint: .topLeading, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                HStack {
                    Image(systemName: "book.pages")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.white)
                        .padding(.leading)
                    MyText(text: "Bookmarks", size: 24, bold: true, alignment: .leading, color: .white)
                        .padding()
                    Spacer()
                }
                Spacer()

                if (videoViewModel.likedVideosProcessing) {
                    ProgressView()
                        .font(.system(size: 32))
                        .brightness(0.5)
                } else {
                    NavigationLink(destination:
                        SingleVideoView(isActive: $isLinkActive, video: current_video)
                           .environmentObject(authModel)
                           .environmentObject(videoViewModel)
                        
                    , isActive: $isLinkActive) {
                        EmptyView()
                    }
                    
                    ScrollView {
                        ForEach(videoViewModel.authModel.liked_videos) { video in
                            
                            Button(action: {
//                                viewModel.playerManager?.updateQueue(with: viewModel.authModel.liked_videos)
//                                viewModel.playerManager?.changeToIndex(to: i, shouldPlay: true)
//                                cur = i
                                current_video = video
                                videoViewModel.playerManager?.pauseCurrentVideo()
                                isLinkActive = true
                            }, label: {
                                HStack {
                                    AsyncImage(url: getThumbnail(video: video)) { mainImage in
                                        mainImage.resizable()
                                            .frame(width: screenSize.width * 0.18, height: screenSize.width * 0.18)
                                    } placeholder: {
                                        
                                        AsyncImage(url: video.author.fileName) { image in
                                            image.resizable()
                                                .frame(width: screenSize.width * 0.18, height: screenSize.width * 0.18)
                                        } placeholder: {
                                            ZStack {
                                                Color("BackgroundColor")
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(2, anchor: .center)
                                                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                                                    .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false))
                                                    .onAppear {
                                                        isAnimating = true
                                                    }
                                                    .frame(width: screenSize.width * 0.18, height: screenSize.width * 0.18)
                                                
                                            }
                                        }
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        MyText(text: "\(video.title)", size: screenSize.width * 0.035, bold: true, alignment: .leading, color: .white)
                                            .lineLimit(2)
                                        MyText(text: "\(video.author.name ?? "")", size: screenSize.width * 0.035, bold: false, alignment: .leading, color: Color("AccentGray"))
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white)
                                        .font(.system(size: screenSize.width * 0.05, weight: .light))
                                        .padding()
                                }
                            })
                        }
                    }
                    .frame(maxWidth: screenSize.width * 0.95, maxHeight: screenSize.height * 0.65)
                    
                }
                
                Spacer()
                
            }
        }
        .onAppear {
            if videoViewModel.likedVideosProcessing {
                Task {
                    await videoViewModel.fetchLikedVideos()
                    print("INIT: got liked videos.")
                    
                }
            }
        }
//        .gesture(DragGesture()
//            .onChanged { event in
//                dragOffset = event.translation.height
//
//            }
//            .onEnded { event in
//                let vel = event.predictedEndTranslation.height
//                let distance = event.translation.height
//                
//                if vel <= -screenSize.height/4 || distance <= -screenSize.height/2 {
//                    if cur + 1 <= viewModel.authModel.liked_videos.count {
//                        cur += 1
//                        
//                    }
//                } else if vel >= screenSize.height/4 || distance >= screenSize.height/2 {
//                    if cur > 0 {
//                        cur -= 1
//                        
//                    }
//                }
//                dragOffset = 0
//            })
        
        

    }
    
    private func getThumbnail(video: Video) -> URL? {
        
        var urlString = video.url?.absoluteString
        
        urlString = urlString?.replacingOccurrences(of: "?tr=f-auto", with: "/tr:w-200,h-200,fo-center/ik-thumbnail.jpg")
        
        return URL(string: urlString ?? "")
    }

    private func myGradient(channel_index: Int) -> [Color] {
        
//        let background = Color(red: 18.0/255, green: 18.0/255, blue: 18.0/255)
        let background = Color(red: 5/255, green: 5/255, blue: 5/255)

        let channel_color = videoViewModel.channels[channel_index].color.opacity(0.8)

//        let purple = Color(red: 0.3803921568627451, green: 0.058823529411764705, blue: 0.4980392156862745)
        var gradient: [Color] = [channel_color]
        
        for _ in 0..<5 {
            gradient.append(background)
        }
        return gradient
    }
}

//struct LikesListView_Previews: PreviewProvider {
//    static var previews: some View {
//        LikesListView()
//    }
//}
