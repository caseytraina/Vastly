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
//        GeometryReader { geo in
            Button(action: {
                clicked = true
                isPlaying = false
            }, label: {
                
                MyText(text: "Full Episode", size: 16, bold: true, alignment: .leading, color: .black)
//                    .brightness(-0.5)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 30)
                    .background(
                    RoundedRectangle(cornerRadius: 100)
                        .foregroundColor(.gray)
                        .brightness(0.5)
                    )
                    .sheet(isPresented: $clicked, onDismiss: {
                        isPlaying = true
                        clicked = false
                    }, content: {
                        FullEpisodeView(video: video)
                    })
                
            })
//            .frame(width: geo.size.width, height: geo.size.height)

            
//        }
    }
}

//struct FullEpisodeButton_Previews: PreviewProvider {
//    static var previews: some View {
//        FullEpisodeButton()
////            .frame(width: screenSize.width * 0.5, height: screenSize.height * 0.1)
//    }
//}
