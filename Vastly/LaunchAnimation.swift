//
//  LaunchAnimation.swift
//  Vastly
//
//  Created by Casey Traina on 9/27/23.
//

import SwiftUI
import AVKit


struct LaunchAnimation: View {
    
    @EnvironmentObject private var authModel: AuthViewModel
    @StateObject var viewModel: VideoViewModel
    
    @State var player: AVPlayer = AVPlayer(url: Bundle.main.url(forResource: "launchAnimation", withExtension: "mp4")!)
    @State private var endObserverToken: Any?

    @State var completed = false
    
    init(authModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: VideoViewModel(authModel: authModel))
//        let playerItem =
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                if !completed {
                    ZStack {
                        Color.accentColor // color of background of animation
                            .ignoresSafeArea()
                        
                        LaunchScreenPlayer(player: $player)
//                        VideoPlayer(player: player)
                            .ignoresSafeArea()
//                            .scaledToFill()
//                            .position(x: 0)
//                            .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
//                            .aspectRatio(CGSize(width: 750, height: 1624), contentMode: .fill)
//                            .clipped()

                    }
    //                    .ignoresSafeArea()
    //                    .position(x: screenSize.width / 2, y: screenSize.height / 2)
                } else {
                    ContentView()
                        .environmentObject(authModel)
                        .environmentObject(viewModel)
                }
            }
            .onAppear {
                player.play()
                
                endObserverToken = NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player.currentItem,
                    queue: .main
                ) { _ in
                    withAnimation {
                        completed = true
                    }
                    NotificationCenter.default.removeObserver(endObserverToken)
                    self.endObserverToken = nil

                }
                
                
                
        }
        }
    }
}

//struct LaunchAnimation_Previews: PreviewProvider {
//    static var previews: some View {
//        LaunchAnimation()
//    }
//}


struct LaunchScreenPlayer: UIViewControllerRepresentable {
    
    @EnvironmentObject var viewModel: VideoViewModel
    
    @Binding var player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        
//        controller.player = player
        controller.allowsPictureInPicturePlayback = false
        controller.exitsFullScreenWhenPlaybackEnds = true
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill

        controller.player?.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
        controller.player?.automaticallyWaitsToMinimizeStalling = false
        controller.player?.currentItem?.preferredPeakBitRate = 4000000
        controller.player?.currentItem?.preferredPeakBitRateForExpensiveNetworks = 3000000
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Update the controller if needed
        // For example, update the player if the active channel changes
        uiViewController.player = player
    }
}
