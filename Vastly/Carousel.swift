//
//  Carousel.swift
//  Vastly
//
//  Created by Casey Traina on 8/10/23.
//

import SwiftUI

struct Carousel: View {
    @EnvironmentObject var viewModel: CatalogViewModel
    @EnvironmentObject var authModel: AuthViewModel
    @State var isNavigationActive = false
    
    @Binding var isPlaying: Bool
    var body: some View {
        ZStack {
            GeometryReader { geo in
                HStack(alignment: .center) {
                    Spacer()
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(viewModel.catalog.channels()) { channel in
                                    Button(action: {
                                        viewModel.changeToChannel(channel, shouldPlay: isPlaying)
                                        withAnimation {
                                            proxy.scrollTo(channel, anchor: .center)
                                        }
                                    }, label: {
                                        MyText(text: channel.title, size: screenSize.width * 0.04, bold: true, alignment: .center, color: viewModel.catalog.activeChannel == channel ? channel.color : Color("AccentGray"))
                                            .padding(.horizontal, 15)
                                            .brightness(0.3)
                                            .padding(.vertical, 10)
                                            .lineLimit(1)
                                            .overlay(
                                                Rectangle()
                                                    .frame(height: 4)
                                                    .foregroundColor(viewModel.catalog.activeChannel == channel ? channel.color : .clear)
                                                    .brightness(0.3),
                                                alignment: .bottom
                                            )
//                                            .background(Capsule()
//                                                .fill(LinearGradient(gradient: Gradient(colors: [selected == viewModel.channels[i] ? selected.color.opacity(0.75) : .white.opacity(0.1), .white.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
//                                                )
//                                            .overlay(Capsule()
//                                                .stroke(Color.black, lineWidth: 1)
//                                                .shadow(color: Color.black.opacity(selected == viewModel.channels[i] ? 1.0 : 0.0), radius: 5, x: 0, y: 5))
                                            .animation(.easeOut, value: viewModel.catalog.activeChannel)
                                            .transition(.opacity)
                                        
                                    })
                                    .id(channel)
                                    .padding(.top)
                                }
                            }
                        }
                        .onChange(of: viewModel.catalog.currentChannel.channel) { newChannel in
                            withAnimation {
                                proxy.scrollTo(newChannel, anchor: .center)
                            }
                        }
//                        .frame(maxWidth: geo.size.width * 0.65)
                    }
                    Spacer()
                    
                }
                .frame(maxHeight: geo.size.height * 0.1)
                .frame(width: geo.size.width)
                .ignoresSafeArea()

            }
        }
    }
}
