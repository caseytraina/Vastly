//
//  ProgressBar.swift
//  Vastly
//
//  Created by Casey Traina on 7/14/23.
//

import SwiftUI
import CoreMedia

struct ProgressBar: View {
    
    @Binding var value: Double
    @Binding var activeChannel: Channel
    
    @State var dragStart: Double = 0.0
    
    @State var beingDragged = false
    
    var video: Video
    
    
    @EnvironmentObject var viewModel: VideoViewModel
    
    @GestureState private var dragState = DragState.inactive
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                
                Rectangle().frame(width: geometry.size.width , height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color("AccentGray"))
//                if video.id == viewModel.playerManager?.getCurrentVideo()?.id {
                    Rectangle().frame(width: min(abs(geometry.size.width * CGFloat(self.value)), geometry.size.width), height: geometry.size.height)
                        .foregroundColor(activeChannel.color)

                
                    Circle()
                        .foregroundColor(activeChannel.color)
                        .frame(width: geometry.size.height * 2 * (beingDragged ? 2 : 1), height: geometry.size.height * 2 * (beingDragged ? 2 : 1))
                        .position(x: CGFloat(self.value) * geometry.size.width, y: geometry.size.height / 2)
                        .gesture(
                            DragGesture()
                                .updating($dragState) { drag, state, transaction in
                                    state = .dragging(translation: drag.translation)
                                }
                                .onEnded(onDragEnded)
                                .onChanged(onDragEnded)

                        )

//                }
            }
            .background(
                Rectangle()  // The larger hitbox
                    .fill(Color.clear) // Make it invisible
                    .frame(width: geometry.size.width, height: geometry.size.height * 12)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .offset(y:25)
            )
            .highPriorityGesture(
                DragGesture()
                    .updating($dragState) { drag, state, transaction in
                        state = .dragging(translation: drag.translation)
                    }
                    .onEnded(onDragEnded)
                    .onChanged(onDragChanged)
            )
        }
    }
    
    private func onDragEnded(drag: DragGesture.Value) {
        beingDragged = false
        let width = drag.translation.width
//        self.value = Double(width / UIScreen.main.bounds.width)
        self.value = dragStart + Double(width / UIScreen.main.bounds.width)

        let trueValue = Double(drag.translation.width / UIScreen.main.bounds.width)
//        self.value = dragStart + trueValue
        // Get the total duration of the video
        guard let duration = viewModel.playerManager?.getPlayer(for: video).currentItem?.duration else { return }
        guard let currentTime = viewModel.playerManager?.getPlayer(for: video).currentTime().seconds else { return }

        // Calculate the new time based on the proportion of the video's duration
//        let newTime = CMTime(seconds: duration.seconds * self.value, preferredTimescale: duration.timescale)
        let newTime = CMTime(seconds: duration.seconds * self.value, preferredTimescale: duration.timescale)

        // Seek to the new time in the video
        viewModel.playerManager?.getPlayer(for: video).seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
//        dragStart = self.value
        dragStart = self.value
    }
    
    private func onDragChanged(drag: DragGesture.Value) {
        beingDragged = true
        let width = drag.translation.width
//        self.value = Double(width / UIScreen.main.bounds.width)
        self.value = dragStart + Double(width / UIScreen.main.bounds.width)

        let trueValue = Double(drag.translation.width / UIScreen.main.bounds.width)
//        self.value = dragStart + trueValue
        // Get the total duration of the video
        guard let duration = viewModel.playerManager?.getPlayer(for: video).currentItem?.duration else { return }
        guard let currentTime = viewModel.playerManager?.getPlayer(for: video).currentTime().seconds else { return }

        // Calculate the new time based on the proportion of the video's duration
//        let newTime = CMTime(seconds: duration.seconds * self.value, preferredTimescale: duration.timescale)
        let newTime = CMTime(seconds: duration.seconds * self.value, preferredTimescale: duration.timescale)

        // Seek to the new time in the video
        viewModel.playerManager?.getPlayer(for: video).seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)

    }
    
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
