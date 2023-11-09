//
//  FullscreenVideoPlayer.swift
//  Vastly
//
//  Created by Casey Traina on 5/23/23.
//

import Foundation
import AVKit
import SwiftUI
import MediaPlayer

struct FullscreenVideoPlayer: UIViewControllerRepresentable {
    
    @EnvironmentObject var viewModel: CatalogViewModel
    
//    var player: AVPlayer?
    @Binding var videoMode: Bool
    
//    var index: Int
//    @Binding var activeChannel: Channel
//
    var video: Video
    @Binding var activeChannel: Channel

    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        
        // Get player from view model here since @EnvironmentObject is available now
        controller.player = viewModel.playerManager?.getPlayer(for: video)
        
//        controller.player = player
        controller.allowsPictureInPicturePlayback = false
        controller.exitsFullScreenWhenPlaybackEnds = true
        controller.showsPlaybackControls = false
        controller.player?.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
        controller.player?.automaticallyWaitsToMinimizeStalling = false
        controller.player?.currentItem?.preferredPeakBitRate = 4000000
        controller.player?.currentItem?.preferredPeakBitRateForExpensiveNetworks = 3000000
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Update the controller if needed
        // For example, update the player if the active channel changes
        uiViewController.player = viewModel.playerManager?.getPlayer(for: video)
    }
}
