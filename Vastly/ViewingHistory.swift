//
//  ViewingHistory.swift
//  Vastly
//
//  Created by Casey Traina on 9/12/23.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import Firebase


struct ViewingHistory: View {
    
    @EnvironmentObject private var authModel: AuthViewModel
    @EnvironmentObject var viewModel: VideoViewModel
    
    @State var processed = false
    
    @Binding var isPlaying: Bool
    @State var isAnimating = true
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            LinearGradient(gradient: Gradient(colors: myGradient(channel_index: 0)), startPoint: .topLeading, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: screenSize.width * 0.06, weight: .light))
                        .foregroundColor(.white)
                        .padding(.leading)
                    MyText(text: "Viewing History", size: screenSize.width * 0.06, bold: true, alignment: .leading, color: .white)
                        .padding()
                    Spacer()
                }

                ScrollView {
                    ForEach(viewModel.viewed_videos.reversed()) { video in
                        
                        NavigationLink(destination: {
                            SingleVideoView(video: video, isPlaying: $isPlaying)
                                .environmentObject(authModel)
                                .environmentObject(viewModel)

                        }, label: {
                            HStack {
                                AsyncImage(url: getThumbnail(video: video)) { mainImage in
                                    mainImage.resizable()
                                        .frame(width: screenSize.width * 0.18, height: screenSize.width * 0.18)
                                } placeholder: {
                                    
                                    AsyncImage(url: video.author.fileName) { image in
                                        image.resizable()
                                            .frame(width: screenSize.width * 0.18, height: screenSize.width * 0.18)
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
                                                .frame(width: screenSize.width * 0.18, height: screenSize.width * 0.18)

                                        }
                                    }
                                }
                                
                                VStack(alignment: .leading) {
                                    MyText(text: "\(video.title)", size: screenSize.width * 0.035, bold: true, alignment: .leading, color: .white)
                                        .lineLimit(2)
                                    MyText(text: "\(video.author.name ?? "")", size: screenSize.width * 0.035, bold: false, alignment: .leading, color: Color("AccentGray"))
                                        .lineLimit(1)
                                }
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white)
                                    .font(.system(size: screenSize.width * 0.05, weight: .light))
                                    .padding()
                                
                                
                            }
                        })
                    }
                }
                .frame(maxWidth: screenSize.width * 0.95, maxHeight: screenSize.height * 0.65)
            
                
            
                
            }
        }
        
    }
    
    private func getThumbnail(video: Video) -> URL? {
        var urlString = video.url?.absoluteString
        
        urlString = urlString?.replacingOccurrences(of: "?tr=f-auto", with: "/tr:w-200,h-200,fo-center/ik-thumbnail.jpg")
        
        return URL(string: urlString ?? "")
    }
    
    private func myGradient(channel_index: Int) -> [Color] {
//        let background = Color(red: 18.0/255, green: 18.0/255, blue: 18.0/255)
        let background = Color(red: 5/255, green: 5/255, blue: 5/255)

        let channel_color = viewModel.channels[channel_index].color.opacity(0.8)

//        let purple = Color(red: 0.3803921568627451, green: 0.058823529411764705, blue: 0.4980392156862745)
        var gradient: [Color] = [channel_color]
        
        for _ in 0..<5 {
            gradient.append(background)
        }
        return gradient
    }
}

//struct LikesListView_Previews: PreviewProvider {
//    static var previews: some View {
//        LikesListView()
//    }
//}