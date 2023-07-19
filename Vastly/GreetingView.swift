//
//  GreetingView.swift
//  Vastly
//
//  Created by Casey Traina on 5/20/23.
//

import SwiftUI

struct GreetingView: View {
    
    @State var name = ""
    @State var email = ""
    @State var password = ""
    @State var phone = ""

    @State var creating = false
    
    @State var isActive = true
    @State var selected: [String] = []
    @EnvironmentObject private var authModel: AuthViewModel
//    @EnvironmentObject var viewModel: VideoViewModel

    var body: some View {
        GeometryReader { geo in
//            NavigationView {
                ZStack {
                    Color("BackgroundColor")
                        .ignoresSafeArea()
                    VStack {
                        MyText(text: "Vastly", size: geo.size.width * 0.075, bold: true, alignment: .center, color: .white)
                            .lineLimit(3)
                            .frame(alignment: .center)
                        Spacer()
                        MyText(text: "Podcast discovery made easy.", size: geo.size.width * 0.075, bold: true, alignment: .center, color: .white)
                            .lineLimit(3)
                            .frame(alignment: .center)
                        Spacer()
                        VStack {
                            NavigationLink(destination: NamePromptView(name: $name, phone: $phone, password: $password, typeOfAccount: .PhoneNumber)
                                .environmentObject(authModel)
//                                .environmentObject(viewModel)
                            )
                            {
                                MyText(text: "Sign Up Free", size: geo.size.width * 0.045, bold: true, alignment: .center, color: .white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.accentColor)
                                    .cornerRadius(10.0)

                            }
                            
                            NavigationLink(destination: PhoneLogin(phone: $phone, name: $name, selected: $selected)
                                .environmentObject(authModel)
//                                .environmentObject(viewModel)
                            ) {
                                MyText(text: "Log In", size: geo.size.width * 0.045, bold: true, alignment: .center, color: .accentColor)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                            }
//                            .overlay(
//                                RoundedRectangle(cornerRadius: 10) // Adjust corner radius
//                                    .stroke(Color.accentColor, lineWidth: 3) // Adjust color and line width for the border
//                            )
                            
                            
                            
                        }
                        .padding()
                        .frame(maxWidth: screenSize.width * 0.9)
                        
                    }
                }
//            }
        }
    }
}

//struct GreetingView_Previews: PreviewProvider {
//    static var previews: some View {
//        GreetingView()
//    }
//}
