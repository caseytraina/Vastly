//
//  CatalogVerticalVideoView.swift
//  Vastly
//
//  Created by Michael Murray on 10/20/23

import SwiftUI
import Combine
import CoreMedia
import AVKit
import AVFoundation
import AudioToolbox

struct CatalogVideoView: View {
    @EnvironmentObject var viewModel: CatalogViewModel
    @EnvironmentObject var authModel: AuthViewModel
    
    // The channel that we want to render (might not be the current active channel)
    var channel: Channel
    // The channel which is currently being viewed
    var currentChannel: ChannelVideos

    @State var videoListNum = 1
    
    @Binding var isPlaying: Bool
    
    @State var liked: Bool = false

    @State private var recent_change = false

    @State private var bioExpanded = false
    
    @Binding var dragOffset: Double
    
    @State var shareURL: URL?
    @Binding var publisherIsTapped: Bool

    var body: some View {
        if let videos = viewModel.catalog.channelVideos(for: channel) {
            ScrollViewReader { proxy in
                GeometryReader { geo in
                    ScrollView {
                        LazyVStack {
                            ForEach(videos.indices, id: \.self) { i in
                                renderVStackVideo(
                                    geoWidth: geo.size.width,
                                    geoHeight: geo.size.height,
                                    video: videos[i],
                                    next: viewModel.catalog.peekNextVideo(), // REMOVE LIKE ORDERING
                                    i: i)
                            }
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scrollDisabled(true)
                    .clipped()
                    .onAppear {
                        // This is going to be rendered for views which aren't active
                        // so that when we scroll sideways we see the new content
                        if channel == currentChannel.channel {
                            viewModel.playCurrentVideo()
                            let currentVideoIndex = self.viewModel.catalog.currentVideoIndex()
                            withAnimation(.easeOut(duration: 0.125)) {
                                proxy.scrollTo(currentVideoIndex, anchor: .top)
                            }
                            if let currentVideo = self.viewModel.catalog.currentVideo {
                                // self.trackAVStatus(for: currentVideo)
                                self.shareURL = videoShareURL(currentVideo)
                            }
                        }
                    }
                    .onChange(of: self.viewModel.currentChannel) { newChannel in
                        if channel == newChannel.channel {
                            proxy.scrollTo(newChannel.currentVideoIndex)
                            
                        }
                    }
//                    .onChange(of: viewModel.isVideoMode) { newVideoMode
//
//                    }
                    .onChange(of: self.viewModel.catalog.currentVideo) { newVideo in
                        if channel == currentChannel.channel {
                            
                            if let newVideo = newVideo {
                                // self.trackAVStatus(for: newVideo)
                                DispatchQueue.main.async {
                                    liked = videoIsLiked(newVideo)
                                }
                                self.shareURL = videoShareURL(newVideo)
                            }
                            
                            let newVideoIndex = self.viewModel.catalog.currentVideoIndex()
                            withAnimation(.easeOut(duration: 0.125)) {
                                proxy.scrollTo(newVideoIndex, anchor: .top)
                            }
                            

                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        } else {
            emptyVideos()
        }
    }
        
    private func emptyVideos() -> some View {
        ZStack {
            Color("BackgroundColor")
            MyText(text: "It seems you've seen all these videos. Try a new channel!", size: screenSize.width * 0.05, bold: true, alignment: .center, color: .white)
        }
        .frame(width: screenSize.width, height: screenSize.height * 0.8)
    }
    
    private func renderVStackVideo(geoWidth: CGFloat, geoHeight: CGFloat, video: Video, next: Video?, i: Int) -> some View {
        VStack(alignment: .leading) {


            Spacer()
            HStack(alignment: .bottom) {
                MyText(text: video.title, size: 20, bold: true, alignment: .leading, color: .gray)
                    .brightness(0.4)
                    .lineLimit(2)
                    .lineSpacing(0)
                Spacer()
            }
            .padding(.horizontal, 10)
            

            if viewModel.videoIsNearCurrent(within: 1, i: i) && channel == currentChannel.channel {
                
                if viewModel.getVideoStatus(video) == .failed {
                    VideoFailedView()
                        .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT+20)// + PROGRESS_BAR_HEIGHT)
                        .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT+20)// + PROGRESS_BAR_HEIGHT)
                } else {
                    if viewModel.getVideoStatus(video) == .ready {
                        
                        ZStack(alignment: .top) {
                            
                            ZStack(alignment: .top) {
                                FullscreenVideoPlayer(videoMode: $viewModel.isVideoMode,
                                                      video: video)
                                .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                                .padding(0)
                                .environmentObject(viewModel)
                                
                                if !viewModel.isVideoMode {
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
                            
                            ProgressBar(video: video, isPlaying: $isPlaying)
                                .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT+20)
                                .padding(0)
                                .environmentObject(viewModel)
                            
                        } // end vstack
                        .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT+20)
                    }  else {
                        VideoThumbnailView(video: video)
                            .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT+20)// + PROGRESS_BAR_HEIGHT)
                        
                    }
                } // end if
            } else {
                VideoThumbnailView(video: video)
                    .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT+20)// + PROGRESS_BAR_HEIGHT)
            }
            
            VStack(alignment: .center) {

                
                HStack(alignment: .top) {
                    MyText(text: viewModel.getVideoTime(video).asString, size: geoWidth * 0.03, bold: false, alignment: .leading, color: .gray)
                        .lineLimit(1)
                        .brightness(0.4)
                    
                    Spacer()
                    MyText(text: viewModel.getVideoDuration(video).asString, size: geoWidth * 0.03, bold: false, alignment: .leading, color: .gray)
                        .lineLimit(1)
                        .brightness(0.4)
                } // end hstack
                .frame(width: PROGRESS_BAR_WIDTH)
                
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
                                .frame(width: geoWidth * 0.125, height: geoWidth * 0.125)
                                .clipShape(RoundedRectangle(cornerRadius: 5)) // Clips the AsyncImage to a rounded
                                //                                        .animation(.easeOut, value: activeChannel)
                                //                                        .transition(.opacity)
                                VStack(alignment: .leading) {
                                    MyText(text: video.author.name ?? "Unknown Author", size: 16, bold: true, alignment: .leading, color: .gray)
                                        .lineLimit(1)
                                        .brightness(0.4)
                                    if let date = video.date {
                                        MyText(text: date, size: 12, bold: false, alignment: .leading, color: .gray)
                                            .lineLimit(1)
                                            .brightness(0.4)
                                    }
                                    
                                }
                                //                                            .animation(.easeOut, value: activeChannel)
                                //                                            .transition(.opacity)
                                Spacer()
                                    
//                            }
                        }
                        .padding(.bottom, 5)
                        
                    })

                    Spacer()
                } // end author hstack
                
                VStack(alignment: .leading) {  // start of bio vstack
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
                                liked.toggle()
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
//                                toggleLike(i)
                                toggleLike(video)
                            }
                        }, label: {
                            if let image = UIImage(named: liked ? "bookmark-fill" : "bookmark") {
                                Image(uiImage: image)
                                    .renderingMode(.template)
                                    .foregroundColor(liked ? .white : .white)
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(width: 24, height: 24)
                                    .transition(.opacity)
                                    .animation(.easeOut, value: liked)
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
                    
                } // end bio vstack
                
                
            }
            .padding(.horizontal, 10)
        }
        .id(i)
        .frame(width: geoWidth, height: geoHeight)
        .clipped()
        .offset(y: channel == viewModel.currentChannel.channel ? dragOffset : 0.0)
//        .offset(y: dragOffset)
    }
    
    private func videoIsLiked(_ video: Video) -> Bool {
        if let user = authModel.current_user {
            if let videos = user.likedVideos {
                return videos.contains(where: { $0 == video.id })
            }
        }
        return false
    }
    
    private func videoShareURL(_ video: Video) -> URL {
        let string = "vastlyapp://open-video?id=\(String(video.id.replacingOccurrences(of: " ", with: "%20")))"
        return URL(string: string) ?? EMPTY_VIDEO.url!
    }
    
    private func toggleLike(_ video: Video) {
        if let user = authModel.current_user {
            if let videos = user.likedVideos {
                if videoIsLiked(video) {
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
    }

}

