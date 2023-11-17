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
    
//    @Binding var value: Double
//    @Binding var activeChannel: Channel
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
//                            .gesture(
//                                DragGesture()
//                                    .updating($dragState) { drag, state, transaction in
//                                        state = .dragging(translation: drag.translation)
//                                    }
//                                    .onEnded(onDragEnded)
//                                    .onChanged(onDragEnded)
//
//                            )

    //                }
                        }
                    }
                }
                .frame(width: PROGRESS_BAR_WIDTH, height: PROGRESS_BAR_HEIGHT)
//                .background(
//                    Rectangle()  // The larger hitbox
//                        .fill(Color.clear) // Make it invisible
//                        .frame(width: geometry.size.width, height: PROGRESS_BAR_HEIGHT * 12)
//                        .position(x: geometry.size.width / 2, y: PROGRESS_BAR_HEIGHT / 2)
//                        .offset(y:25)
//                )

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
//                    .onEnded(onDragEnded)
//                    .onChanged(onDragChanged)
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
    
//    private func onDragEnded(drag: DragGesture.Value) {
//        beingDragged = false
//        let width = drag.translation.width
////        self.value = Double(width / UIScreen.main.bounds.width)
//        self.value = dragStart + Double(width / UIScreen.main.bounds.width)
//
//        let trueValue = Double(drag.translation.width / UIScreen.main.bounds.width)
////        self.value = dragStart + trueValue
//        // Get the total duration of the video
//        guard let duration = videoViewModel.playerManager?.getPlayer(for: video).items().last?.duration else { return }
//        guard let currentTime = videoViewModel.playerManager?.getPlayer(for: video).items().last?.currentTime().seconds else { return }
//
//        // Calculate the new time based on the proportion of the video's duration
////        let newTime = CMTime(seconds: duration.seconds * self.value, preferredTimescale: duration.timescale)
//        let newTime = CMTime(seconds: duration.seconds * self.value, preferredTimescale: duration.timescale)
//
//        // Seek to the new time in the video
//        videoViewModel.playerManager?.getPlayer(for: video).items().last?.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
////        dragStart = self.value
//        dragStart = self.value
//    }
//    
//    private func onDragChanged(drag: DragGesture.Value) {
//        beingDragged = true
//        let width = drag.translation.width
////        self.value = Double(width / UIScreen.main.bounds.width)
//        self.value = dragStart + Double(width / UIScreen.main.bounds.width)
//
//        let trueValue = Double(drag.translation.width / UIScreen.main.bounds.width)
////        self.value = dragStart + trueValue
//        // Get the total duration of the video
//        guard let duration = videoViewModel.playerManager?.getPlayer(for: video).items().last?.duration else { return }
//        guard let currentTime = videoViewModel.playerManager?.getPlayer(for: video).items().last?.currentTime().seconds else { return }
//
//        // Calculate the new time based on the proportion of the video's duration
////        let newTime = CMTime(seconds: duration.seconds * self.value, preferredTimescale: duration.timescale)
//        let newTime = CMTime(seconds: duration.seconds * self.value, preferredTimescale: duration.timescale)
//
//        // Seek to the new time in the video
//        videoViewModel.playerManager?.getPlayer(for: video).items().last?.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
//
//    }
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


//struct ProgressBar_Previews: PreviewProvider {
// 
//    static var previews: some View {
//        ProgressBar(value: 0.7, maxValue: 1.0)
//    }
//}
