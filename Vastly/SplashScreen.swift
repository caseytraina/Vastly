//
//  SplashScreen.swift
//  Vastly
//
//  Created by Casey Traina on 9/6/23.
//

import SwiftUI
import AVKit

struct VideoPlayerView: UIViewControllerRepresentable {
    let videoName: String
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        
        guard let path = Bundle.main.path(forResource: videoName, ofType: "mp4") else {
            debugPrint("\(videoName).mp4 not found")
            return controller
        }
        
        let player = AVPlayer(url: URL(fileURLWithPath: path))
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        player.play()
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}


struct SplashScreen: View {
    var body: some View {
        ZStack {
            Color(red: 18/255, green: 18/255, blue: 18/255) // #121212
                .edgesIgnoringSafeArea(.all)
            
            VideoPlayerView(videoName: "vastlyGif")
                .frame(width: screenSize.width, height: screenSize.width)
//                .aspectRatio(contentMode: .fit)
//                .clipped()
        }
        
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
