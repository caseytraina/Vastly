//
//  TutorialView.swift
//  Vastly
//
//  Created by Casey Traina on 6/26/23.
//

import SwiftUI

struct TutorialView: View {
    
    @Binding var showTutorial: Bool
    
    var messages = [
    "Swipe up or down to explore the next video in this channel",
    "Explore channels above or from the channel guide in the bottom right",
    "Liked videos can be found in your profile",
    "Toggle audio mode to hide the video"
    ]
    
    var icons = [
    "hand.draw",
    "hand.tap",
    "heart",
    "hand.tap"

    ]
    
    @State var toggleOn = true

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                    .opacity(0.8)
                TabView {
                    ForEach(0..<4) { index in
                        
                        renderVStackTab(geoWidth: geo.size.width, index: index)
                        
                        // end vstack
                        .frame(width: geo.size.width, height: geo.size.height)
//                        Spacer()
                    }
//                    .ignoresSafeArea()
//                    Spacer()
                }
//                .ignoresSafeArea()

//                .ignoresSafeArea()
                .tabViewStyle(PageTabViewStyle())
//                .ignoresSafeArea()
            }
            .frame(width: geo.size.width, height: geo.size.height)
//            .ignoresSafeArea()

        }
//        .ignoresSafeArea()
        
    }
    
    private func renderVStackTab(geoWidth: CGFloat, index: Int) -> some View {
        VStack {
            
            HStack(alignment: .center) {
                Spacer()
                HStack {
                        Button(action: {
                            
                        }, label: {
                                
                            MyText(text: "For You", size: screenSize.width * 0.04, bold: true, alignment: .center, color: .white)
                                .padding(.horizontal, 15)
                                .lineLimit(1)
                                .background(Capsule()
                                    .fill(LinearGradient(gradient: Gradient(colors: [Channel.foryou.color.opacity(0.75)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                )
                                .overlay(Capsule()
                                    .stroke(Color.black, lineWidth: 1)
                                    .shadow(color: Color.black.opacity(1.0), radius: 5, x: 0, y: 5))
                                .opacity(index == 1 ? 1 : 0)
                        })
                        .padding(.top)
                        .padding(.bottom)
                    
//                                    .padding(0)
                    
                    Spacer()
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(.white)
                            .font(.system(size: geoWidth * 0.08, weight: .light))
                            .shadow(radius: 2.0)
                            .padding(.trailing, 10)
                            .padding(.bottom, 10)
                            .padding(.bottom)
                            .opacity(index == 2 ? 1 : 0)
                }
            }
//                            .frame(maxHeight: screenSize.height*0.05)
            .frame(height: screenSize.height*0.075)
            .frame(width: screenSize.width)
            .ignoresSafeArea()
            .padding(.bottom)
            
            Spacer()
            Spacer()
            
            VStack {

                HStack {
                    Spacer()
                    Toggle(isOn: $toggleOn) {
                        
                    }
                    .toggleStyle(AudioToggleStyle(color: .accentColor))
                    .padding(.trailing, 40)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    .frame(width: screenSize.width * 0.15)
                    .opacity(index == 3 ? 1 : 0)

                }
            
            
                VStack {
                    //                                Spacer()
                    //                                Spacer()
                    //                            }
                    VStack {
                        
                        Image(systemName: icons[index])
                            .foregroundColor(.white)
                            .font(.system(size: geoWidth * 0.1, weight: .light))
                        
                        MyText(text: messages[index], size: geoWidth * 0.04, bold: true, alignment: .center, color: .white)
                            .padding()
                            .frame(maxWidth: geoWidth * 0.75)
                        
                    }
                    .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT + PROGRESS_BAR_HEIGHT)
                    
                    HStack(alignment: .top) {
                        MyText(text: "Jun 2023", size: geoWidth * 0.03, bold: false, alignment: .leading, color: .clear)
                            .lineLimit(1)
                            .padding(.leading)
                    }
                
                    HStack {
                        Spacer()
                        
                        Image(systemName: "heart.fill")// : "heart")
                            .foregroundColor(.red)
                            .font(.system(size: screenSize.width * 0.05, weight: .medium))
                            .padding(.horizontal)
                    }
                    .frame(width: geoWidth, height: geoWidth * 0.125)
                    .padding(.vertical, 5)
                    .opacity(index == 2 ? 1 : 0)

                    
                    
                    
                    
                    VStack {
                        Spacer()
                        
                        Button(action: {showTutorial = true}) {
                            MyText(text: "Start Watching!", size: geoWidth * 0.04, bold: false, alignment: .center, color: .white)
                                .padding(10)
                                .background( Color.accentColor)
                                .cornerRadius(10.0)
                        }
                        .disabled(index != 3)
                        .opacity(index == 3 ? 1 : 0)
                        MyText(text: "Autoplay is always on.", size: geoWidth * 0.03, bold: true, alignment: .center, color: .white)
                            .lineLimit(2)
                        
                        
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "list.bullet.below.rectangle")
                                .foregroundColor(.white)
                                .font(.system(size: geoWidth * 0.05, weight: .medium))
                        }
                        .padding(.horizontal)
                        .frame(width: screenSize.width)
                        .opacity(index == 1 ? 1 : 0)
                        .padding(.bottom, 5)

                        
                    }
                }
//                                .frame(width: screenSize.width, height: screenSize.height * 0.8)
            }
//                            .ignoresSafeArea()
            .frame(maxHeight: screenSize.height * 0.8)
//                            Spacer()
        }
    }
}

struct TutorialView_Previews: PreviewProvider {
    
    @State static var here = false
    
    static var previews: some View {
        TutorialView(showTutorial: $here)
    }
}
/*
var body: some View {
    
    
    
    Group {
        if viewModel.isProcessing {
            LoadingView()
        } else {
            ZStack {
                VStack {
                    Carousel(isPlaying: $playing, selected: $activeChannel)
                        .environmentObject(viewModel)
                        .environmentObject(authModel)
                        .frame(maxHeight: screenSize.height*0.125)
                        .padding()
                    Spacer()
                    ZStack {
                        
                        ScrollViewReader { proxy in
                            ScrollView (.horizontal, showsIndicators: false) {
                                HStack {
                                    
                                    ForEach(Channel.allCases, id: \.self) { channel in
                                        if abs((Channel.allCases.firstIndex(of: activeChannel) ?? 0) - (Channel.allCases.firstIndex(of: channel) ?? 0)) <= 1 {
                                            
                                            
                                            //                                        if abs(channel_index - Channel.allCases.first(where: {$0 == channel})) <= 1 {
                                            VerticalVideoView(activeChannel: $activeChannel, current_playing: $video_indices[channel_index], isPlaying: $playing, dragOffset: $dragOffset, channelGuidePressed: $channelGuidePressed, channel: channel, publisherIsTapped: $publisherIsTapped)
                                                .environmentObject(viewModel)
                                                .environmentObject(authModel)
                                                .frame(width: screenSize.width, height: screenSize.height * 0.8)
//                                                    .blur(radius: channel == activeChannel ? 0 : 3)
                                                .id(channel)
                                            
                                        } else {
                                            Color("BackgroundColor")
                                                .frame(width: screenSize.width, height: screenSize.height * 0.8)
//                                                    .blur(radius: channel == activeChannel ? 0 : 3)
                                                .id(channel)
                                        }
                                        
                                    } //end for each
                                    
                                } // end HStack
                                .offset(x: offset.width)
                            } //end scrollview
                            .scrollDisabled(true)
                            .frame(width: screenSize.width, height: screenSize.height * 0.8)
                            
                        }// end scroll view reader
                        
                        
                        if channelGuidePressed {
                            ChannelSelectorView(activeChannel: $activeChannel, channel_index: $channel_index, video_indices: $video_indices, channelsExpanded: $channelGuidePressed)
                                .environmentObject(viewModel)
                                .frame(height: screenSize.height * 0.8)

                        }
                        
                        
                    } // end zstack
                    .frame(height: screenSize.height * 0.8)


                }
                
                if publisherIsTapped {
                    AuthorProfileView(author: getVideo(i: video_indices[channel_index], in: activeChannel).author, publisherIsTapped: $publisherIsTapped)
//                            .frame(width: screenSize.width, height: screenSize.height)
//                            .transition(.opacity)
//                            .animation(.easeOut, value: publisherIsTapped)
                }
            }
        }
    }
*/
