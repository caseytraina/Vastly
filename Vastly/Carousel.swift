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
//
    @State var isNavigationActive = false
    
    @Binding var isPlaying: Bool
    @Binding var selected: Channel
    @Binding var channel_index: Int
    var body: some View {
        ZStack {
//            Color(.black)
//                .ignoresSafeArea()
            GeometryReader { geo in
                HStack(alignment: .center) {
//                    Spacer()
                    Spacer()
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(viewModel.channels.indices) { i in
                                    Button(action: {
//                                        selected = Channel.allCases[i]
                                        viewModel.playerManager?.pauseCurrentVideo()
                                        channel_index = i
                                        withAnimation {
                                            proxy.scrollTo(i, anchor: .center)
                                        }
                                    }, label: {
                                        MyText(text: viewModel.channels[i].title, size: screenSize.width * 0.04, bold: true, alignment: .center, color: selected == viewModel.channels[i] ? .white : Color("AccentGray"))
                                            .padding(.horizontal, 15)
                                            .padding(.vertical, 10)
                                            .lineLimit(1)
                                            .overlay(
                                                Rectangle()
                                                    .frame(height: 4)
                                                    .foregroundColor(selected == viewModel.channels[i] ? .white : .clear),
                                                alignment: .bottom
                                            )
//                                            .background(Capsule()
//                                                .fill(LinearGradient(gradient: Gradient(colors: [selected == viewModel.channels[i] ? selected.color.opacity(0.75) : .white.opacity(0.1), .white.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
//                                                )
//                                            .overlay(Capsule()
//                                                .stroke(Color.black, lineWidth: 1)
//                                                .shadow(color: Color.black.opacity(selected == viewModel.channels[i] ? 1.0 : 0.0), radius: 5, x: 0, y: 5))
                                            .animation(.easeOut, value: selected)
                                            .transition(.opacity)
                                        
                                    })
                                    .id(i)
                                    .padding(.top)
                                }
                            }
                        }
                        .onChange(of: channel_index) { newIndex in
                            withAnimation {
                                proxy.scrollTo(newIndex, anchor: .center)
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

//struct Carousel_Previews: PreviewProvider {
//    static var previews: some View {
//        Carousel()
//    }
//}
