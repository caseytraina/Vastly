//
//  AudioOverlay.swift
//  Vastly
//
//  Created by Casey Traina on 7/27/23.
//

import SwiftUI
import CoreMedia

struct AudioOverlay: View {
    
    let author: Author
    @State private var isAnimating = false

    var video: Video
    
    @State var time: CMTime?
    @State var duration: CMTime?
//    @State var currentDuration: CMTime =
//    @State var totalDuration: CMTime
    
    @EnvironmentObject var viewModel: CatalogViewModel
    
    @Binding var playing: Bool
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color("BackgroundColor")
                VStack {

                    VStack {

                        ZStack {
                            AsyncImage(url: author.fileName) { image in
                                image.resizable()
                                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                                    .onAppear { isAnimating = true }
                                    .onDisappear { isAnimating = false }
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
                                    
                                }
                            }
                            .frame(width: VIDEO_HEIGHT, height: VIDEO_HEIGHT)
                            .cornerRadius(10)
                            .onTapGesture {
                                playing.toggle()
                            }
                            if !playing {
                                Image(systemName: "play.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: screenSize.width * 0.15, weight: .light))
                                    .shadow(radius: 2.0)
                                    .onTapGesture {
                                        playing.toggle()
                                    }
                            }
                        }

//                        MyText(text: author.name ?? "", size: geo.size.width * 0.04, bold: true, alignment: .center, color: .white)

                        
                    }
                }
            }
        }
        .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
        .onAppear {
            
            let player = viewModel.playerManager?.getPlayer(for: self.video)
            
//            time = v.currentTime()
            duration = viewModel.playerManager?.getPlayer(for: self.video).currentItem?.duration
            player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
                self.time = time
//                self.playerTime = time
//                self.playerProgress = time.seconds / (duration?.seconds ?? 1.0)
            }
        }

    }
        
}

extension CMTime {
    var asString: String {
        let totalSeconds = self.seconds.isNaN ? 1 : Int(round(self.seconds))
        let seconds = totalSeconds % 60
        let minutes = totalSeconds / 60
        return String(format: "%01d:%02d", minutes, seconds)
    }
}

//struct AudioOverlay_Previews: PreviewProvider {
//    static var previews: some View {
//        AudioOverlay(author: EXAMPLE_AUTHOR)
//    }
//}
