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
    
    init(activeChannel: Binding<Channel>, current_playing: Binding<Int>, isPlaying: Binding<Bool>, dragOffset: Binding<Double>, channel: Channel, publisherIsTapped: Binding<Bool>) {
        self._activeChannel = activeChannel
        self._current_playing = current_playing
        self._isPlaying = isPlaying
        self._dragOffset = dragOffset
        self.channel = channel
        self._publisherIsTapped = publisherIsTapped
    }
    
    
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
                    .clipped()
                    .onAppear {
                        if abs((viewModel.channels.firstIndex(of: activeChannel) ?? 0) - (viewModel.channels.firstIndex(of: channel) ?? 0)) <= 1 {
                            videoListNum = 15
                        } else {
                            videoListNum = 1
                        }

                        if channel == activeChannel {
                            
                            print("APPEAR \(current_playing)")
                            previous = current_playing
                            trackAVStatus(for: getVideo(current_playing))
//                            play(current_playing)
//                            viewModel.playerManager?.pauseAllOthers(except: getVideo(current_playing))
                            shareURL = videoShareURL(getVideo(current_playing))
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                proxy.scrollTo(current_playing, anchor: .top)
                            }
                        }

                    }
                    .onChange(of: current_playing) { newIndex in
                        if channel == activeChannel {
                            print("APPEAR CURRENT")

                            if newIndex >= vids.count {
//                                current_playing = newIndex - 1
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
                                
                                if newIndex >= videoListNum - 2 {
                                    videoListNum = min(videoListNum + 15, vids.count)
                                }
                                
                                previous = newIndex
                            }
                            
                            shareURL = videoShareURL(getVideo(current_playing))
                                                     

                        }
                    }
                    .onChange(of: activeChannel) { newChannel in
                        print("APPEAR ACTIVE")

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
//            HStack {
//                if let title {
//                    MyText(text: title, size: 24, bold: true, alignment: .leading, color: .white)
//                        .padding(.horizontal)
//                }
//            }
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
            

            //                                }
            
            //                                if (abs(i - current_playing) <= 1 && channel == activeChannel) ||
            //                                    (i == current_playing && abs((Channel.allCases.firstIndex(of: activeChannel) ?? 0) - (Channel.allCases.firstIndex(of: channel) ?? 0)) <= 1) {
            if (abs(i - current_playing) <= 1 && channel == activeChannel) {
                if let manager = viewModel.playerManager {

                    if videoFailed {
                        VideoFailedView()
                            .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT+20)// + PROGRESS_BAR_HEIGHT)
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
//                                    VStack {
//                                        HStack {
//                                            Spacer()
//                                            
//                                            Toggle(isOn: $videoMode) {
//                                                
//                                            }
//                                            .toggleStyle(AudioToggleStyle(color: channel.color))
//                                            .padding(10)
//                                            .frame(width: screenSize.width * 0.15)
//                                        }
//                                        Spacer()
//                                    }
                                }

                                if i == current_playing {
                                    
                                    ProgressBar(value: $playerProgress, activeChannel: $activeChannel, video: video, isPlaying: $isPlaying)
                                        .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT+20)
                                        .padding(0)
                                        .environmentObject(viewModel)
                                }
                            } // end vstack
                            .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT+20)
                        }  else {
                            VideoThumbnailView(video: video)
                                .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT+20)// + PROGRESS_BAR_HEIGHT)
//                                                        VideoLoadingView()
//                                                            .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT + PROGRESS_BAR_HEIGHT)
                        }
                    } // end if
                }
            } else if (i == current_playing && channel != activeChannel) {
                VideoThumbnailView(video: video)
                    .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT+20)// + PROGRESS_BAR_HEIGHT)
            } else {
                VideoLoadingView()
                    .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT+20)// + PROGRESS_BAR_HEIGHT)
            } // end abs if
            
            VStack(alignment: .center) {
                
                HStack(alignment: .top) {
                    MyText(text: playerTime.asString, size: geoWidth * 0.03, bold: false, alignment: .leading, color: .gray)
                        .lineLimit(1)
                        .brightness(0.4)
                    
                    Spacer()
                    MyText(text: playerDuration.asString, size: geoWidth * 0.03, bold: false, alignment: .leading, color: .gray)
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
                            if channel == activeChannel || i == current_playing {
                                AsyncImage(url: AuthorURL(i)) { image in
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
                                    MyText(text: video.date ?? "", size: 12, bold: false, alignment: .leading, color: .gray)
                                        .lineLimit(1)
                                        .brightness(0.4)
                                    
                                }
                                //                                            .animation(.easeOut, value: activeChannel)
                                //                                            .transition(.opacity)
                                Spacer()
                                    
                            }
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
                                liked.toggle()
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                toggleLike(i)
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
                    
                } // end vstack
//                .frame(width: geoWidth)
                
            }
            .padding(.horizontal, 10)
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
        return URL(string: string) ?? EMPTY_VIDEO.url!
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

