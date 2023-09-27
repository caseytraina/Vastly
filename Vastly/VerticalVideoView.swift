//
//  VerticalVideoView.swift
//  Vastly
//
//  Created by Casey Traina on 8/10/23.
//

import SwiftUI
import Combine
import CoreMedia
import AVKit
import AVFoundation
import AudioToolbox

struct VerticalVideoView: View {
    
    @EnvironmentObject var viewModel: VideoViewModel
    @EnvironmentObject var authModel: AuthViewModel

    @Binding var activeChannel: Channel
    @Binding var current_playing: Int
    
    @State private var cancellables = Set<AnyCancellable>()

    @State private var statusObserver: AnyCancellable?
    @State var isLoaded = false
    @State var videoFailed = false

    @State var videoListNum = 1
    
    @Binding var isPlaying: Bool
    
    @State var videoMode: Bool = true
    @State var liked: Bool = false

    @State private var playerProgress: Double = 0
    @State private var playerDuration: CMTime = CMTime()
    @State private var playerTime: CMTime = CMTime()
    
    @State var previous = 0
    @State var previous_channel: Channel = FOR_YOU_CHANNEL

    @State private var recent_change = false

    @State private var timeObserverToken: Any?
    @State private var endObserverToken: Any?
    @State private var timedPlayer: AVPlayer?

    @State private var bioExpanded = false
    
    @Binding var dragOffset: Double
    
    @State var audioPlayer: AVAudioPlayer?

    @State var shareURL: URL?
    
    var channel: Channel
    
    @Binding var publisherIsTapped: Bool

    var body: some View {
        if let vids = viewModel.videos[channel] {
            ScrollViewReader { proxy in
                GeometryReader { geo in

                    ScrollView {
                        LazyVStack {
                            ForEach(0..<min(vids.count, videoListNum), id: \.self) { i in
                                renderVStackVideo(
                                    geoWidth: geo.size.width,
                                    geoHeight: geo.size.height,
                                    video: vids[i],
                                    next: i+1 < vids.count ? vids[i+1] : nil,
                                    i: i)
                            }
                        }
//                        } // end of if
                    } // end scrollview
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scrollDisabled(true)
//                    .id(activeChannel)
                    .clipped()
                    .onAppear {

                        if abs((viewModel.channels.firstIndex(of: activeChannel) ?? 0) - (viewModel.channels.firstIndex(of: channel) ?? 0)) <= 1 {
                            videoListNum = 15
                        } else {
                            videoListNum = 1
                        }

                        if channel == activeChannel {
                            
                            withAnimation(.easeOut(duration: 0.125)) {
                                proxy.scrollTo(current_playing, anchor: .top)
                            }
                            
                            previous = current_playing
                            trackAVStatus(for: getVideo(current_playing))
                            play(current_playing)
                            viewModel.playerManager?.pauseAllOthers(except: getVideo(current_playing))
                            shareURL = videoShareURL(getVideo(current_playing))
                        }

                    }
                    .onChange(of: current_playing) { newIndex in
                        if channel == activeChannel {
                            
                            if newIndex >= vids.count {
                                current_playing = newIndex - 1
                            } else {
                                
                                recent_change = true
                                videoListNum = min(vids.count, videoListNum)
                                
                                trackAVStatus(for: getVideo(newIndex))
                                
                                withAnimation(.easeOut(duration: 0.125)) {
                                    proxy.scrollTo(newIndex, anchor: .top)
                                }
                                
                                
                                DispatchQueue.main.async {
                                    liked = false
                                    liked = videoIsLiked(current_playing)
                                }
                                //                        pause(previous)
                                //                        play(newIndex)
                                
                                if newIndex >= videoListNum - 2 {
                                    videoListNum = min(videoListNum + 15, vids.count)
                                }
                                
                                previous = newIndex
                            }
                            
                            shareURL = videoShareURL(getVideo(current_playing))
                                                     

                        }
                    }
                    .onChange(of: activeChannel) { newChannel in

                        if abs((viewModel.channels.firstIndex(of: newChannel) ?? 0) - (viewModel.channels.firstIndex(of: channel) ?? 0)) <= 1 {
                            videoListNum = videoListNum < 15 ? min(vids.count, 15) : videoListNum
                        }
                        
                        if channel == newChannel {
                            
//                            isPlaying = true
                            recent_change = true
                            videoListNum = min(vids.count, videoListNum)
                            trackAVStatus(for: getVideo(current_playing))
                            //                        viewModel.playerManager?.pause(for: viewModel.videos[previous_channel]?[previous] ?? EMPTY_VIDEO)
                            
                            withAnimation(.easeOut(duration: 0.125)) {
                                proxy.scrollTo(current_playing, anchor: .top)
                            }
                            previous_channel = newChannel
                            shareURL = videoShareURL(getVideo(current_playing))

                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
//                .frame(maxHeight: .infinity)
            }
//            .frame(maxHeight: .infinity)
        }

    }
    
    private func renderVStackVideo(geoWidth: CGFloat, geoHeight: CGFloat, video: Video, next: Video?, i: Int) -> some View {
        VStack(alignment: .leading) {
            HStack {
                
                if !videoMode {
                    VStack(alignment: .leading) {
                        MyText(text: "Audio autoplay is on", size: geoWidth * 0.04, bold: false, alignment: .leading, color: .white)
                        MyText(text: "Put Vastly in your pocket and go", size: geoWidth * 0.04, bold: false, alignment: .leading, color: Color("AccentGray"))
                    }
                    .padding(.horizontal)
                }
                
                
                Spacer()
                Toggle(isOn: $videoMode) {
                    
                }
                .toggleStyle(AudioToggleStyle(color: channel.color))
                .padding(.trailing, 40)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .frame(width: screenSize.width * 0.15)
            } // end hstack
            //                                }
            
            //                                if (abs(i - current_playing) <= 1 && channel == activeChannel) ||
            //                                    (i == current_playing && abs((Channel.allCases.firstIndex(of: activeChannel) ?? 0) - (Channel.allCases.firstIndex(of: channel) ?? 0)) <= 1) {
            if (abs(i - current_playing) <= 1 && channel == activeChannel) {
                if let manager = viewModel.playerManager {

                    if videoFailed {
                        VideoFailedView()
                            .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)// + PROGRESS_BAR_HEIGHT)
                    } else {
                        if isLoaded {
                            
                            ZStack {
                                
                                ZStack {
                                    FullscreenVideoPlayer(videoMode: $videoMode, video: video, activeChannel: $activeChannel)
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

                                if i == current_playing {
                                    
                                    ProgressBar(value: $playerProgress, activeChannel: $activeChannel, video: video, isPlaying: $isPlaying)
                                        .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                                        .padding(0)
                                        .environmentObject(viewModel)
                                }
                            } // end vstack
                            .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                        }  else {
                            VideoThumbnailView(video: video)
                                .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)// + PROGRESS_BAR_HEIGHT)
//                                                        VideoLoadingView()
//                                                            .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT + PROGRESS_BAR_HEIGHT)
                        }
                    } // end if
                }
            } else if (i == current_playing && channel != activeChannel) {
                VideoThumbnailView(video: video)
                    .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)// + PROGRESS_BAR_HEIGHT)
            } else {
                VideoLoadingView()
                    .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)// + PROGRESS_BAR_HEIGHT)
            } // end abs if
            
            
            HStack(alignment: .top) {
                MyText(text: video.date ?? "", size: geoWidth * 0.03, bold: false, alignment: .leading, color: Color("AccentGray"))
                    .lineLimit(1)
                    .padding(.leading)
                
                Spacer()
                MyText(text: "\(playerTime.asString) / \(playerDuration.asString)", size: geoWidth * 0.03, bold: false, alignment: .leading, color: Color("AccentGray"))
                    .lineLimit(1)
                    .padding(.trailing)
            } // end hstack
            
            
            HStack {
                
                Button(action: {
                    withAnimation {
                        publisherIsTapped = true
                    }
                }, label: {
                    
                    
                    HStack(alignment: .center) {
                        if channel == activeChannel || i == current_playing {
                            AsyncImage(url: AuthorURL(i)) { image in
                                image.resizable()
                            } placeholder: {
                                ZStack {
                                    Color("BackgroundColor")
                                    MyText(text: "?", size: geoWidth * 0.05, bold: true, alignment: .center, color: .white)
                                }
                            }
                            .frame(width: geoWidth * 0.125, height: geoWidth * 0.125)
                            .clipShape(RoundedRectangle(cornerRadius: 5)) // Clips the AsyncImage to a rounded
                            .padding(.leading)
                            //                                        .animation(.easeOut, value: activeChannel)
                            //                                        .transition(.opacity)
                            
                            MyText(text: video.author.name ?? "Unknown Author", size: geoWidth * 0.04, bold: true, alignment: .leading, color: .white)
                                .padding(0)
                                .lineLimit(2)
                            //                                            .animation(.easeOut, value: activeChannel)
                            //                                            .transition(.opacity)
                            Spacer()
                        }
                    }
                    
                })
                
                .zIndex(1)
                //                                    .padding(.bottom)
                
                Spacer()
                Image(systemName: liked ? "heart.fill" : "heart")
                    .foregroundColor(liked ? .red : .white)
                    .font(.system(size: screenSize.width * 0.05, weight: .medium))
                    .padding(.horizontal)
                    .onTapGesture {
                        DispatchQueue.main.async {
                            liked.toggle()
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            toggleLike(i)
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeOut, value: liked)
            } // end hstack
            .padding(.vertical, 5)
            .frame(width: geoWidth)
            VStack(alignment: .leading) {
                
                MyText(text: video.title, size: geoWidth * 0.05, bold: true, alignment: .leading, color: .white)
                    .lineLimit(2)
                    .padding(.horizontal, 15)
                
                    HStack {
                        //                                        VStack {
                        MyText(text: video.bio, size: geoWidth * 0.04, bold: false, alignment: .leading, color: Color("AccentGray"))
                            .truncationMode(.tail)
                            .padding(.horizontal, 15)
                            .lineLimit(bioExpanded ? 8 : 4)
                        Spacer()
                    }
                    .onTapGesture {
                        bioExpanded.toggle()
                    }
                .frame(maxWidth: geoWidth * 0.9)
                .padding(.bottom, 5)
                
                if let url = video.youtubeURL {
                    HStack {
                        FullEpisodeButton(video: video, isPlaying: $isPlaying)
//                                                    .frame(width: geo.size.width * 0.04)
                        Spacer()
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 15)
                }
                
                Spacer()
                //                                Spacer()
                if i == current_playing {
                    HStack {
                        Image(systemName: "arrow.down")
                            .foregroundColor(Color("AccentGray"))
                            .font(.system(size: geoWidth * 0.05, weight: .light))
                            .padding(.leading)
                        MyText(text: next != nil ? "\(next!.title)" : "Swipe up for more!", size: geoWidth * 0.03, bold: true, alignment: .leading, color: Color("AccentGray"))
                        Spacer()
                        
                        if let shareURL {
                            ShareLink(item: shareURL) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.white)
                                    .font(.system(size: geoWidth * 0.05, weight: .medium))
                            }
                        }
                        
                        NavigationLink(destination: NewSearchBar(all_authors: viewModel.authors, oldPlaying: $isPlaying)
                            .environmentObject(authModel)
                            .environmentObject(viewModel)
                        ) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .font(.system(size: geoWidth * 0.05, weight: .medium))
                        }
                        .padding(.horizontal)

                        
                        
                    }
                    .frame(width: geoWidth)
                }
            } // end vstack
            .frame(width: geoWidth)
            
            
        }
        .id(i)
        .frame(width: geoWidth, height: geoHeight)
        .clipped()
        .offset(y: channel == activeChannel ? dragOffset : 0.0)
    }
    
    
    private func videoIsLiked(_ i: Int) -> Bool {
        if let user = authModel.current_user {
            if let videos = user.likedVideos {
                return videos.contains(where: { $0 == getVideo(i).id })
            }
        }
        return false
    }
    
    private func videoShareURL(_ video: Video) -> URL {
        let string = "vastlyapp://open-video?id=\(String(video.id.replacingOccurrences(of: " ", with: "%20")))"
        return URL(string: string)!
    }
    
    private func getVideo(_ i: Int) -> Video {
        if let vids = viewModel.videos[channel] {
            if i < vids.count {
                return vids[i]
            }
        }
        return EMPTY_VIDEO
    }
    
    private func getNext() -> Video {
        return getVideo(current_playing + 1)
    }
    
    private func toggleLike(_ i: Int) {
        if let user = authModel.current_user {
            if let videos = user.likedVideos {
                if videoIsLiked(i) {
                    Task {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        await authModel.removeLikeFrom(getVideo(i))
                    }
                } else {
                    Task {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        await authModel.addLikeTo(getVideo(i))
                    }
                }
            }
        }
    }
    
    private func play(_ i: Int) {
        if isPlaying && channel == activeChannel {
            viewModel.playerManager?.getPlayer(for: getVideo(i)).play()
        }
    }
    
    private func pause(_ i: Int) {
        viewModel.playerManager?.getPlayer(for: getVideo(i)).pause()
    }
    
    private func AuthorURL(_ i: Int) -> URL? {
        return viewModel.videos[channel]?[i].author.fileName
    }
    
    private func trackAVStatus(for video: Video) {
        statusObserver?.cancel()

        if let player = viewModel.playerManager?.getPlayer(for: video) {
            statusObserver = AnyCancellable(
                (player.currentItem?
                    .publisher(for: \.status)
                    .sink { status in
                        switch status {
                        case .unknown:
                            // Handle unknown status
                            print("UNKNOWN")
                            videoFailed = false

                            isLoaded = false
                        case .readyToPlay:
                            isLoaded = true
                            videoFailed = false
//                            isPlaying = true
                            viewModel.playerManager?.playCurrentVideo()
                        case .failed:
                            // Handle failed status
                            videoFailed = true
//                            viewModel.videos[activeChannel]?.remove(at: current_playing)
//                            videoListNum -= 1
//                            print("DELETED")
//                            nextVideo()
                            isLoaded = false
                        @unknown default:
                            // Handle other unknown cases
                            videoFailed = false
                            isLoaded = false
                        }
                    })!
            )
            
            switchedPlayer()
            observePlayer(to: player)
            
        }
    }
    
    private func switchedPlayer() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        viewModel.playerManager?.getPlayer(for: getVideo(current_playing))
            .publisher(for: \.rate)
            .sink { newRate in
                if newRate == 0 && !recent_change {
                    isPlaying = false
                } else {
                    isPlaying = true
                }
                viewModel.playerManager?.updateNowPlayingInfo(for: getVideo(current_playing))
                recent_change = false
            }
            .store(in: &cancellables)
    }
    
    private func playSound() {

        if let path = Bundle.main.path(forResource: "Blow", ofType: "aiff") {
            let soundUrl = URL(fileURLWithPath: path)
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundUrl)
                audioPlayer?.play()
            } catch {
                print("Error initializing AVAudioPlayer.")
            }
        }
    }
    
    private func observePlayer(to player: AVPlayer) {
                
//        DispatchQueue.global(qos: .userInitiated).async {
        print("Attached observer to \(player.currentItem)")
            
        player.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                DispatchQueue.main.async {
                    let duration = player.currentItem?.asset.duration
                    self.playerDuration = duration ?? CMTime(value: 0, timescale: 1000)
                    
                    timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1000), queue: .main) { time in
                        self.playerTime = time
                        self.playerProgress = time.seconds / (duration?.seconds ?? 1.0)
                        self.timedPlayer = player
                    }
                }
            }
        
        print("Started Observing Video")
        
        if let endObserverToken = endObserverToken {
            NotificationCenter.default.removeObserver(endObserverToken)
            self.endObserverToken = nil
        }
        
        endObserverToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            recent_change = true
            playSound()
            videoCompleted(for: getVideo(current_playing), with: authModel.user, profile: authModel.current_user)
            player.seek(to: CMTime.zero)

            player.pause()
            current_playing += 1;
//            recent_change = false
        }
    }
    
}

