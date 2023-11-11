//
//  SignOutView.swift
//  Vastly
//
//  Created by Casey Traina on 5/21/23.
//

import SwiftUI

struct ProfileView: View {
    
    @EnvironmentObject private var authModel: AuthViewModel
    @EnvironmentObject var viewModel: CatalogViewModel
    
    @State var isAnimating = false
    
    @Binding var isPlaying: Bool

    var body: some View {

        GeometryReader { geo in
                ZStack {
                    Color("BackgroundColor")
                        .ignoresSafeArea()

                    VStack {

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
                                .font(.system(size: 18, weight: .light))
                                .padding()
                            MyText(text: "Name", size: 18, bold: false, alignment: .leading, color: .white)

                            Spacer()
                            MyText(text: "\(authModel.current_user?.firstName?.capitalized ?? "") \(authModel.current_user?.lastName?.capitalized ?? "")", size: 18, bold: true, alignment: .leading, color: .white)
                                .padding()
                            //                                .padding()                        }
                        }
//                        .frame(width: geo.size.width*0.75)
                        

                        HStack {
                            Image(systemName: ((authModel.current_user?.phoneNumber) != "") ? "phone" : "envelope")
                                .foregroundColor(.white)
                                .font(.system(size: geo.size.width * 0.05, weight: .light))
                                .padding()
                            MyText(text: (authModel.current_user?.phoneNumber != "") ? "Phone Number" : "Email", size: 18, bold: false, alignment: .leading, color: .white)

                            Spacer()
                            MyText(text: ((authModel.current_user?.phoneNumber) != "") ? "\(authModel.current_user?.phoneNumber ?? authModel.current_user?.email ?? "")" : "\(authModel.current_user?.email ?? "")", size: 18, bold: true, alignment: .leading, color: .white)
                                .padding()
                        }
                        
                        NavigationLink(destination: {
                            ViewingHistory(isPlaying: $isPlaying)
                                .environmentObject(authModel)
                                .environmentObject(viewModel)
                        }, label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundColor(.white)
                                    .padding()

                                    MyText(text: "Viewing History", size: screenSize.width * 0.04, bold: true, alignment: .leading, color: .white)
                                
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
                            viewModel.pauseCurrentVideo()
                            Task {
                                do {
                                    isPlaying = false
                                    try await authModel.signOut()
                                } catch {
                                    print(error)
                                }
                            }
                            
                        }, label: {
                            MyText(text: "Sign Out", size: geo.size.width * 0.05, bold: true, alignment: .center, color: .gray)
                        })
                        Spacer()
                        
                    }
                }
                .onAppear {
                    logScreenSwitch(to: "Profile Screen")
                }
        }
    }
}

//struct SignOutView_Previews: PreviewProvider {
//    static var previews: some View {
//        SignOutView()
//    }
//}
