//
//  SignOutView.swift
//  Vastly
//
//  Created by Casey Traina on 5/21/23.
//

import SwiftUI

struct ProfileView: View {
    
    @EnvironmentObject private var authModel: AuthViewModel
    @EnvironmentObject var viewModel: VideoViewModel
    
    @State var isAnimating = false
    
    @Binding var isPlaying: Bool
    
//    @Binding var channel: Channel
//    @Binding var current: Int
    
    var body: some View {

        GeometryReader { geo in
                ZStack {
                    Color("BackgroundColor")
                        .ignoresSafeArea()
//                    LinearGradient(gradient: Gradient(colors: myGradient(channel_index: 0)), startPoint: .topLeading, endPoint: .bottom)
//                        .ignoresSafeArea()
                    VStack {
//
//                        Image(systemName: "person.circle")
//                            .foregroundColor(.white)
//                            .font(.system(size: geo.size.width * 0.2, weight: .light))
//                            .padding()
                        
//                        MyText(text: "\(authModel.current_user?.firstName?.capitalized.first ?? "V")\(authModel.current_user?.lastName?.capitalized.first ?? "V")", size: geo.size.width * 0.2, bold: true, alignment: .leading, color: .white)
//                            .padding()
//
                        
                        Circle()
                            .fill(Color.white)  // Fill color for the circle
                            .frame(width: geo.size.width*0.3, height: geo.size.width*0.3)  // Size of the circle
                            .overlay(
                                MyText(text: "\(authModel.current_user?.firstName?.capitalized.first ?? "V")\(authModel.current_user?.lastName?.capitalized.first ?? "V")", size: geo.size.width * 0.1, bold: true, alignment: .leading, color: .accentColor)
 // Text size
                            )
                            .padding(.top, geo.size.width*0.1)

                            .padding()
                        

                        
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.white)
                                .font(.system(size: geo.size.width * 0.05, weight: .light))
                                .padding()
                            Spacer()
                            MyText(text: "\(authModel.current_user?.firstName?.capitalized ?? "") \(authModel.current_user?.lastName?.capitalized ?? "")", size: geo.size.width * 0.05, bold: true, alignment: .leading, color: .white)
                                .padding()
                            //                                .padding()                        }
                        }
//                        .frame(width: geo.size.width*0.75)
                        

                        HStack {
                            Image(systemName: ((authModel.current_user?.phoneNumber) != "") ? "phone" : "envelope")
                                .foregroundColor(.white)
                                .font(.system(size: geo.size.width * 0.05, weight: .light))
                                .padding()
                            Spacer()
                            MyText(text: ((authModel.current_user?.phoneNumber) != "") ? "\(authModel.current_user?.phoneNumber ?? authModel.current_user?.email ?? "")" : "\(authModel.current_user?.email ?? "")", size: geo.size.width * 0.05, bold: true, alignment: .leading, color: .white)
                                .padding()
                        }
                        
                            
                        NavigationLink(destination: {
                            LikesListView(isPlaying: $isPlaying)
                                .environmentObject(authModel)
                                .environmentObject(viewModel)
                        }, label: {
                            HStack {

                            
                                AsyncImage(url: EMPTY_AUTHOR.fileName) { image in
                                    image.resizable()
                                        .frame(width: screenSize.width * 0.2, height: screenSize.width * 0.2)
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
                                
                                VStack(alignment: .leading) {
                                    MyText(text: "Likes", size: screenSize.width * 0.04, bold: true, alignment: .leading, color: .white)
                                    MyText(text: "\(authModel.liked_videos.count) Videos", size: screenSize.width * 0.04, bold: false, alignment: .leading, color: Color("AccentGray"))
                                }
                                .padding()
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white)
                                    .font(.system(size: geo.size.width * 0.05, weight: .light))
                                    .padding()
                                
                            
                            }
                            
                        })

//                        .frame(width: geo.size.width*0.75)

                        Spacer()
                        Button(action: {
                            if let manager = viewModel.playerManager {
                                manager.pauseCurrentVideo()
                            }
                            Task {
                                do {
                                    isPlaying = false
                                    try await authModel.signOut()
                                } catch {
                                    print(error)
                                }
                            }
                            
                        }, label: {
                            MyText(text: "Sign Out", size: geo.size.width * 0.05, bold: true, alignment: .center, color: .red)
                        })
                        
                    }
                }
                .onAppear {
//                    Task {
//                        await authModel.configureUser(authModel.user?.phoneNumber ?? authModel.user?.email ?? "")
//                    }
                    logScreenSwitch(to: "Profile Screen")
                }
        }
    }
    
    private func myGradient(channel_index: Int) -> [Color] {
        
//        let background = Color(red: 18.0/255, green: 18.0/255, blue: 18.0/255)
        let background = Color(red: 5/255, green: 5/255, blue: 5/255)

        let channel_color = Channel.allCases[channel_index].color.opacity(0.8)

//        let purple = Color(red: 0.3803921568627451, green: 0.058823529411764705, blue: 0.4980392156862745)
        var gradient: [Color] = [channel_color]
        
        for _ in 0..<5 {
            gradient.append(background)
        }
        return gradient
    }
}

//struct SignOutView_Previews: PreviewProvider {
//    static var previews: some View {
//        SignOutView()
//    }
//}
