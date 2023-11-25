//
//  ProgressBar.swift
//  Vastly
//
//  Created by Casey Traina on 7/14/23.
//

import SwiftUI
import CoreMedia

let PROGRESS_BAR_WIDTH = screenSize.width * 0.95

struct ProgressBar: View {

    @State var progress = 0.0
    @State var dragStart: Double = 0.0
    
    @State var beingDragged = false
    
    var video: Video
    
    @Binding var isPlaying: Bool
    
    @EnvironmentObject var videoViewModel: CatalogViewModel
    
    @GestureState private var dragState = DragState.inactive
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                EmptyView()
                Spacer()
                ZStack(alignment: .leading) {
                    if let progress = videoViewModel.playerManager?.playerTimes[video.id] {
                        if let duration = videoViewModel.playerManager?.getDurationOfVideo(video: video) {
                            
    
                    RoundedRectangle(cornerRadius: 5).frame(width: PROGRESS_BAR_WIDTH , height: PROGRESS_BAR_HEIGHT)
                        .opacity(0.3)
                        .foregroundColor(Color("AccentGray"))
    //                if video.id == viewModel.playerManager?.getCurrentVideo()?.id {
                            RoundedRectangle(cornerRadius: 5).frame(width: min(abs(PROGRESS_BAR_WIDTH * CGFloat(progress.seconds/duration.seconds)), PROGRESS_BAR_WIDTH), height: PROGRESS_BAR_HEIGHT)
                            .foregroundColor(videoViewModel.currentChannel.channel.color)

                    
                        Circle()
                            .foregroundColor(videoViewModel.currentChannel.channel.color)
                            .frame(width: geometry.size.height * 2 * (beingDragged ? 2 : 1), height: PROGRESS_BAR_HEIGHT * 2 * (beingDragged ? 2 : 1))
                            .position(x: CGFloat(progress.seconds/duration.seconds) * PROGRESS_BAR_WIDTH, y: PROGRESS_BAR_HEIGHT / 2)

                        }
                    }
                }
                .frame(width: PROGRESS_BAR_WIDTH, height: PROGRESS_BAR_HEIGHT)

            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())  // Makes the entire area tappable
            )
            .highPriorityGesture(
                DragGesture()
                    .updating($dragState) { drag, state, transaction in
                        state = .dragging(translation: drag.translation)
                    }
                    .onEnded(onDragEnded)
                    .onChanged(onDragChanged)
            )
            .onTapGesture(count: 1) {
                isPlaying.toggle()
            }
            .onTapGesture(count: 2) { event in
                if event.x < geometry.size.width / 2 {
                    print("Seek Backward.")
                    videoViewModel.playerManager?.seekBackward(by: 15.0)
                } else {
                    print("Seek Forward.")
                    videoViewModel.playerManager?.seekForward(by: 15.0)
                }
                    
            }
            
        }
    }
    
    private func onDragEnded(drag: DragGesture.Value) {
        beingDragged = false
        let width = drag.translation.width
        let value = dragStart + Double(width / UIScreen.main.bounds.width)
        
        if let progress = videoViewModel.playerManager?.playerTimes[video.id] {
            if let duration = videoViewModel.playerManager?.getDurationOfVideo(video: video) {

                // Calculate the new time based on the proportion of the video's duration
                //        let newTime = CMTime(seconds: duration.seconds * self.value, preferredTimescale: duration.timescale)
                let newTime = CMTime(seconds: duration.seconds * value, preferredTimescale: duration.timescale)
                
                // Seek to the new time in the video
                videoViewModel.playerManager?.seekTo(time: newTime)
                dragStart = value
            }
        }
    }
    
    private func onDragChanged(drag: DragGesture.Value) {
        beingDragged = true
        let width = drag.translation.width
        let value = dragStart + Double(width / UIScreen.main.bounds.width)

        let trueValue = Double(drag.translation.width / UIScreen.main.bounds.width)
        // Get the total duration of the video
        if let progress = videoViewModel.playerManager?.playerTimes[video.id] {
            if let duration = videoViewModel.playerManager?.getDurationOfVideo(video: video) {
                
                // Calculate the new time based on the proportion of the video's duration
                let newTime = CMTime(seconds: duration.seconds * value, preferredTimescale: duration.timescale)
                
                // Seek to the new time in the video
                videoViewModel.playerManager?.seekTo(time: newTime)
            }
        }

    }
//    
    enum DragState {
        case inactive
        case dragging(translation: CGSize)
        
        var translation: CGSize {
            switch self {
            case .inactive:
                return .zero
            case .dragging(let translation):
                return translation
            }
        }
        
        var isDragging: Bool {
            switch self {
            case .inactive:
                return false
            case .dragging:
                return true
            }
        }
    }
}

