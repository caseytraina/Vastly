//
//  ChannelSelector.swift
//  Vastly
//
//  Created by Casey Traina on 5/26/23.
//

import SwiftUI

struct ChannelSelectorView: View {
    
    @Binding var activeChannel: Channel
    @Binding var channel_index: Int
//    @Binding var isActive: Bool
    
    @Binding var video_indices: [Int]
    @Binding var channelsExpanded: Bool
//    @Binding var dragOffset: Double

    @EnvironmentObject var viewModel: VideoViewModel
    
    var body: some View {
//        GeometryReader { geo in
                
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                VStack(alignment: .center) {
                    if channelsExpanded {
                        HStack {
                            Spacer()
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.system(size: screenSize.width * 0.05, weight: .medium))
                                .padding()
                                .onTapGesture {
                                    channelsExpanded = false
                                }
                        }
                        
                    }
                ScrollView {
                    ForEach(Channel.allCases.indices) { i in
                            Button(action: {
                                print("HERE'S I: \(i)")
                                switchChannel(i: i)
                                channelsExpanded = false
                            }) {
                                VStack {
                                    Spacer()
                                    HStack{
                                        Text(Channel.allCases[i].title)
                                            .foregroundColor(.white)
                                            .font(Font.custom("CircularStd-Bold", size: screenSize.width * 0.05))
                                            .frame(maxWidth: .infinity,alignment: .leading)
                                            .frame(height: screenSize.height * 0.07, alignment: .bottomLeading)
                                            .lineLimit(2)
                                        Spacer()
                                    }
                                }
                                
                            }
                            .padding()
                            .frame(width: screenSize.width*0.95)
                            .background(
                                Image("\(Channel.allCases[i].imageName)")
                                    .resizable()
                                    .scaledToFill()
                                    .overlay(
                                        LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .bottomLeading, endPoint: .top)
                                    )
                            )
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: i == channel_index ? 2 : 0))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.7), lineWidth: i == channel_index ? 4 : 0))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.4), lineWidth: i == channel_index ? 6 : 0))
                            .cornerRadius(10.0)
                        }
                    }


                }
                .onAppear {
                    logScreenSwitch(to: "Channel Guide")
                }
            }
//            .highPriorityGesture(
//                DragGesture()
//                    .onChanged({ event in
//                        dragOffset = event.translation.height < -90 ? -90 : event.translation.height
//
//                    })
//                    .onEnded({ event in
//                    let swipeThreshold: CGFloat = screenSize.height / 4
//                    if event.predictedEndTranslation.height >= swipeThreshold || event.translation.height >= swipeThreshold {
//                        channelsExpanded = false
//                    } else if event.predictedEndTranslation.height <= -swipeThreshold || event.translation.height <= -swipeThreshold {
//                        channelsExpanded = true
//                    }
//                    dragOffset = 0
//                })
//            )
            .onAppear {
                logScreenSwitch(to: "Channel Guide")
            }
//            .simultaneousGesture(
//                DragGesture().onEnded({ event in
//                    let swipeThreshold: CGFloat = screenSize.height / 4
//                    if event.predictedEndTranslation.height >= swipeThreshold || event.translation.height >= swipeThreshold {
//                        channelsExpanded = false
//                    }
//                })
//            )

//        }
    }
    
    private func switchChannel(i: Int) {
        
        viewModel.playerManager?.pauseCurrentVideo()

        channel_index = i;
        activeChannel = Channel.allCases[channel_index]
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        let newIndex = video_indices[i]
        
        viewModel.playerManager?.changeToChannel(to: activeChannel, shouldPlay: true, newIndex: newIndex)
        
//        isActive = false
    }
}

//struct ChannelSelectorView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChannelSelectorView()
//    }
//}
