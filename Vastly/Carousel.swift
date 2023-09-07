//
//  Carousel.swift
//  Vastly
//
//  Created by Casey Traina on 8/10/23.
//

import SwiftUI

struct Carousel: View {
    
    @EnvironmentObject var viewModel: VideoViewModel
    @EnvironmentObject var authModel: AuthViewModel
//
    @State var isNavigationActive = false
    
    @Binding var isPlaying: Bool
    @Binding var selected: Channel
    
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
                                ForEach(Channel.allCases.indices) { i in
                                    Button(action: {
                                        selected = Channel.allCases[i]
                                        withAnimation {
                                            proxy.scrollTo(Channel.allCases[i], anchor: .center)
                                        }
                                    }, label: {
                                        MyText(text: Channel.allCases[i].title, size: screenSize.width * 0.04, bold: true, alignment: .center, color: selected == Channel.allCases[i] ? .white : Color("AccentGray"))
                                            .padding(.horizontal, 15)
                                            .lineLimit(1)
                                            .background(Capsule()
                                                .fill(LinearGradient(gradient: Gradient(colors: [selected == Channel.allCases[i] ? selected.color.opacity(0.75) : .white.opacity(0.1), .white.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                                )
                                            .overlay(Capsule()
                                                .stroke(Color.black, lineWidth: 1)
                                                .shadow(color: Color.black.opacity(selected == Channel.allCases[i] ? 1.0 : 0.0), radius: 5, x: 0, y: 5))
                                            .animation(.easeOut, value: selected)
                                            .transition(.opacity)
                                        
                                    })
                                    .id(Channel.allCases[i])
                                    .padding(.top)
                                }
                            }
                        }
                        .onChange(of: selected) { newChannel in
                            withAnimation {
                                proxy.scrollTo(Channel.allCases.first(where: { $0 == newChannel }), anchor: .center)
                            }
                        }
//                        .frame(maxWidth: geo.size.width * 0.65)
                    }
                    Spacer()
                    
                
                    Button(action: {
                        isNavigationActive = true
                        isPlaying = false
                    }, label: {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(.white)
                            .font(.system(size: geo.size.width * 0.08, weight: .light))
                            .shadow(radius: 2.0)

                    })
                    .background(
                        NavigationLink(destination: ProfileView(isPlaying: $isPlaying)
                                        .environmentObject(authModel)
                                        .environmentObject(viewModel),
                                       isActive: $isNavigationActive,
                                       label: { EmptyView() })
                    )
                    .padding(10)
//                    .frame(maxWidth: screenSize.width * 0.15)
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
