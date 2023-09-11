//
//  HomeView.swift
//  Vastly
//
//  Created by Casey Traina on 5/9/23.
//

import SwiftUI
import AVKit

struct HomeView: View {
//    @EnvironmentObject var viewModel: VideoViewModel
    @StateObject var viewModel: VideoViewModel

    @EnvironmentObject var authModel: AuthViewModel

    @State var channel_index = 0
    
    init(authModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: VideoViewModel(authModel: authModel))
    }
    
    var body: some View {
        
        // Create Background + Display Videos
        
        ZStack {
//            LinearGradient(gradient: Gradient(colors: myGradient(channel_index: channel_index)), startPoint: .topLeading, endPoint: .bottom)
//                .ignoresSafeArea()
//                .transition(.opacity)
//                .animation(.easeInOut(duration: 1.0), value: channel_index)

            Color("BackgroundColor")
                .ignoresSafeArea()
            
            ForEach(0..<Channel.allCases.count) { index in
                LinearGradient(gradient: Gradient(colors: myGradient(channel_index: index)), startPoint: .topLeading, endPoint: .bottom)
                    .ignoresSafeArea()
                    .opacity(channel_index == index ? 1 : 0)
                    .animation(.easeInOut(duration: 0.75), value: channel_index)
            }
            
            VStack {
                NewVideoView(channel_index: $channel_index)
                    .environmentObject(viewModel)
                    .environmentObject(authModel)
            }
        }
        
    }
    // Creates Gradient
    private func myGradient(channel_index: Int) -> [Color] {
        
//        let background = Color(red: 18.0/255, green: 18.0/255, blue: 18.0/255)
//        let background = Color("BackgroundColor")
        let background = Color.black

        let channel_color = Channel.allCases[channel_index].color.opacity(0.8)

//        let purple = Color(red: 0.3803921568627451, green: 0.058823529411764705, blue: 0.4980392156862745)
        var gradient: [Color] = [channel_color]
        
        for _ in 0..<5 {
            gradient.append(background)
        }
        return gradient
    }
}

