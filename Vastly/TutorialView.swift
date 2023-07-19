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
    "Swipe left or tap the left/right arrows to explore the next video in this channel",
    "Click the icon in the bottom right to open the channel guide",
    "Click the up/down arrows below to explore different channels"
    ]
    
    var icons = [
    "hand.draw",
    "hand.tap",
    "hand.tap"
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                    .opacity(0.8)
                TabView {
                    ForEach(0..<3) { index in
                        VStack {
                            VStack {
                                Spacer()
                                Spacer()
                            }
                            Image(systemName: icons[index])
                                .foregroundColor(.white)
                                .font(.system(size: geo.size.width * 0.1, weight: .light))
                            
                            MyText(text: messages[index], size: geo.size.width * 0.04, bold: true, alignment: .center, color: .white)
                                .padding()
                                .frame(maxWidth: geo.size.width * 0.75)
                            VStack {
                                Spacer()
                                
                                if index == 2 {
                                    Button(action: {showTutorial = true}) {
                                        MyText(text: "Start Watching!", size: geo.size.width * 0.04, bold: false, alignment: .center, color: .white)
                                            .padding(10)
                                            .background( Color.accentColor)
                                            .cornerRadius(10.0)
                                    }
                                }
                                
                                Spacer()
//                                if index == 2 {
//                                    HStack {
//                                        HStack {
//                                            Image(systemName: "arrow.down")
//                                                .foregroundColor(.accentColor)
//                                                .font(.system(size: geo.size.width * 0.05, weight: .light))
//
//                                            MyText(text: "Tap here for next channel", size: geo.size.width * 0.04, bold: false, alignment: .leading, color: .accentColor)
//                                                .lineLimit(1)
//                                        }
//                                        .padding(10)
//                                        .overlay(
//                                            Rectangle()
//                                                .stroke(Color.white, lineWidth: 2)
//                                        )
//
//                                        Spacer()
//                                    }
//                                    .padding(10)
//
////                                    .padding(20)
//                                }
                                
                                if index == 1 {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "menucard")
                                            .foregroundColor(Color.accentColor)
                                            .font(.system(size: geo.size.width * 0.05, weight: .light))
                                            .padding(20)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                            )
                                        
                                    }
                                    .offset(y: 40)
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Hide the default TabView index
            .ignoresSafeArea()
            }
        }
        
    }
}

struct TutorialView_Previews: PreviewProvider {
    
    @State static var here = false
    
    static var previews: some View {
        TutorialView(showTutorial: $here)
    }
}
