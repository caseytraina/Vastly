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
    @StateObject var viewModel: CatalogViewModel
    @StateObject var videoViewModel: VideoViewModel
    
    @State var player: AVPlayer = AVPlayer(url: Bundle.main.url(forResource: "launchAnimation", withExtension: "mp4")!)
    @State private var endObserverToken: Any?

    @State var completed = false
    
    init(authModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: CatalogViewModel(authModel: authModel))
        _videoViewModel = StateObject(wrappedValue: VideoViewModel(authModel: authModel))
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                if !completed {
                    ZStack {
                        Color.accentColor // color of background of animation
                            .ignoresSafeArea()
                        LaunchScreenPlayer(player: $player)
                            .ignoresSafeArea()
                    }
                } else {
                    ContentView()
                        .environmentObject(authModel)
                        .environmentObject(viewModel)
                        .environmentObject(videoViewModel)
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

struct LaunchScreenPlayer: UIViewControllerRepresentable {
    
    @EnvironmentObject var viewModel: CatalogViewModel
    
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
