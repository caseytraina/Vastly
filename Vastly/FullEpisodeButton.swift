//
//  FullEpisodeButton.swift
//  Vastly
//
//  Created by Casey Traina on 9/5/23.
//

import SwiftUI

struct FullEpisodeButton: View {
    
    @State var clicked = false
    
    let video: Video
    @Binding var isPlaying: Bool

    var body: some View {
        GeometryReader { geo in
            Button(action: {
                clicked = true
                isPlaying = false
            }, label: {
                
                HStack {
                    Image(systemName: "play.fill")
                        .font(.system(size: geo.size.width * 0.05))
                        .foregroundColor(.accentColor)
                    MyText(text: "Full Episode", size: geo.size.width * 0.04, bold: false, alignment: .leading, color: Color("BackgroundColor"))
                }
                .padding(10)
                .background(
                Capsule()
                    .foregroundColor(Color("AccentGray"))
    //                .frame(width: geo.size.width, height: geo.size.height)
                )
                .sheet(isPresented: $clicked, onDismiss: {
                    isPlaying = true
                    clicked = false
                }, content: {
                    FullEpisodeView(video: video)
                })
                
//            .frame(width: geo.size.width, height: geo.size.height)
            })
        }
    }
}

//struct FullEpisodeButton_Previews: PreviewProvider {
//    static var previews: some View {
//        FullEpisodeButton()
////            .frame(width: screenSize.width * 0.5, height: screenSize.height * 0.1)
//    }
//}
