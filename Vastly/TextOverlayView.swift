//
//  TextOverlayView.swift
//  Vastly
//
//  Created by Casey Traina on 5/20/23.
//

import SwiftUI
import AVKit

struct TextOverlayView: View {
    
    @Binding var video_index: Int
    
    @Binding var channel_index: Int
    @Binding var activeChannel: Channel
    
    @State var isPressed = false
    
    @Binding var isPlaying: Bool
    @EnvironmentObject private var authModel: AuthViewModel

    var videos: [Channel : [Video]]
    @Binding var isActive: Bool

    var body: some View {
        GeometryReader { geo in
//            NavigationView {
                VStack{
                    
                    // VIDEO VIEW
                    
//                    Spacer(minLength: VIDEO_HEIGHT * 1.5)
                    
                    // BIO TEXT
                    HStack {
                        Spacer()
                        VStack {
                            
                            
                            Button(action: {
                                DispatchQueue.global(qos: .userInitiated).async {
                                    
                                    channel_index -= 1;
                                    
                                    if channel_index < 0 {
                                        channel_index = 0
                                    }
                                    
                                    activeChannel = Channel.allCases[channel_index]
                                }
                                
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                
                            }) {
                                Image(systemName: "chevron.up")
                                    .foregroundColor(channel_index == 0 ? Color("AccentGray") : Color.white)
                                    .font(.system(size: geo.size.width * 0.06, weight: .light))
                            }
                            .disabled(channel_index == 0)
                            
                            HStack {
                                Button(action: {
                                    if video_index > 0 {
                                        video_index -= 1
                                    }
                                }) {
                                    Image(systemName: "backward.end.fill")
                                        .foregroundColor(video_index == 0 ? Color("AccentGray") : Color.white)
                                        .font(.system(size: geo.size.width * 0.06, weight: .light))

                                }
                                .padding(.horizontal, 35)
                                Button(action: {
                                    isPlaying.toggle()
                                }) {
                                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .foregroundColor(Color.white)
                                        .font(.system(size: geo.size.width * 0.15, weight: .light))
                                }

                                Button(action: {
                                    if let vids = videos[activeChannel] {
                                        if video_index < (vids.count-1) {
                                            video_index += 1
                                        }
                                    }
                                }) {
                                    Image(systemName: "forward.end.fill")
                                        .foregroundColor(Color.white)
                                        .font(.system(size: geo.size.width * 0.06, weight: .light))

                                }
                                .padding(.horizontal, 35)
                            }
                            .padding(.vertical, 35)
                            .frame(alignment: .center)
                            
                            Button(action: {
                                DispatchQueue.global(qos: .userInitiated).async {
                                    
                                    channel_index += 1;
                                    
                                    if channel_index == Channel.allCases.count {
                                        channel_index = 0
                                    }
                                    
                                    activeChannel = Channel.allCases[channel_index]
                                }
                                
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                
                            }) {
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color.white)
                                    .font(.system(size: geo.size.width * 0.06, weight: .light))
                            }
                                                        
                        }
                        Spacer()
                    }
                }
            Spacer()

        }
    }
    
    private func nextChannel() -> Channel {

        if (channel_index + 1) >= Channel.allCases.count {
            return Channel.allCases[0]
        }
        return Channel.allCases[channel_index + 1]
    }
    
}
