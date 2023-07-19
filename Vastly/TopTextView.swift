//
//  TopTextView.swift
//  Vastly
//
//  Created by Casey Traina on 5/29/23.
//

import SwiftUI

struct TopTextView: View {
    
    @EnvironmentObject var viewModel: VideoViewModel
    @EnvironmentObject var authModel: AuthViewModel
    
    @Binding var activeChannel: Channel
    @Binding var video_index: Int
    
    var videos: [Channel : [Video]]
    
    @State var isPressed = false
    
    @State var isNavigationActive = false
    
//    @Binding var isActive: Bool
    
    @Binding var isChannel: Bool
    @Binding var isDiscover: Bool
    @State var isProfile: Bool = false
    
    @Binding var videoIsOn: Bool
    
    @Binding var isPlaying: Bool
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                            isChannel = true
                            isDiscover = false
//                            isProfile = false
                    }) {
                        MyText(text: "Channels", size: geo.size.width * 0.035, bold: true, alignment: .center, color: isChannel ? .white : Color("AccentGray"))
                            .frame(width: screenSize.width / 4)
                            .background(Capsule()
                                .fill(LinearGradient(gradient: Gradient(colors: [isChannel ? activeChannel.color.opacity(0.75) : .white.opacity(0.1), .white.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: Color.black.opacity(isChannel ? 1.0 : 0.0), radius: 5, x: 0, y: 5))
                            .overlay(Capsule().stroke(Color.black, lineWidth: 1))
                            .animation(nil)

                    }


                    Button(action: {
                            isChannel = false
                            isDiscover = true
//                            isProfile = false
                    }) {
                        MyText(text: "For You", size: geo.size.width * 0.035, bold: true, alignment: .center, color: isDiscover ? .white : Color("AccentGray"))
                            .frame(width: screenSize.width / 4)
                            .background(Capsule()
                                .fill(LinearGradient(gradient: Gradient(colors: [isDiscover ? activeChannel.color.opacity(0.75) : .white.opacity(0.1), .white.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: Color.black.opacity(isDiscover ? 1.0 : 0.0), radius: 5, x: 0, y: 5))
                            .overlay(Capsule().stroke(Color.black, lineWidth: 1))

                    }
                    Button(action: {
                        self.isPlaying = false
                        self.isNavigationActive = true
                    }) {
                        MyText(text: "Profile", size: geo.size.width * 0.035, bold: true, alignment: .center, color: isProfile ? .white : Color("AccentGray"))
                            .frame(width: screenSize.width / 4)
                            .background(Capsule()
                                .fill(LinearGradient(gradient: Gradient(colors: [isProfile ? activeChannel.color.opacity(0.75) : .white.opacity(0.1), .white.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: Color.black.opacity(isProfile ? 1.0 : 0.0), radius: 5, x: 0, y: 5))
                            .overlay(Capsule().stroke(Color.black, lineWidth: 1))
                    }
                    .background(
                        NavigationLink(destination: ProfileView(isPlaying: $isPlaying)
                                        .environmentObject(authModel)
                                        .environmentObject(viewModel),
                                       isActive: $isNavigationActive,
                                       label: { EmptyView() })
                    )
                    
                    Spacer()
                }
//                .sheet(isPresented: $isProfile, onDismiss: {
//                    isDiscover = true
//                }, content: {
//                    ProfileView()
//            })

                Spacer()
                HStack {
                    MyText(text: isDiscover ? "For You" : activeChannel.rawValue, size: geo.size.width * 0.06, bold: true, alignment: .leading, color: .white)
                        .lineLimit(2)

                    Spacer()
                    if !isDiscover {
                        Toggle(isOn: $videoIsOn) {
                            
                        }
                        .toggleStyle(AudioToggleStyle(color: activeChannel.color))
                        .padding(.trailing, 40)
                        .onChange(of: videoIsOn) { value in
                            print("videoIsOn is now: \(value)")
                        }
                        .frame(width: screenSize.width * 0.15)
                    }
                }

            }
        }
    }
    
    
//    enum Field {
//        case channel, title, bio, author, date
//    }
//
//    private func getInfo(field: Field, i: Int) -> String {
//        if let channelVideos = videos[activeChannel], i < channelVideos.count {
//            let video = channelVideos[i]
//            switch field {
//            case .channel:
//                return channel.rawValue
//            case .title:
//                return video.title
//            case .author:
//                return video.author
//            case .bio:
//                return video.bio
//            case .date:
//                return video.date ?? ""
//            }
//
//        }
//        return "No data for \(activeChannel) Channel"
//    }
    
}

//struct TopTextView_Previews: PreviewProvider {
//    static var previews: some View {
//        TopTextView()
//    }
//}
