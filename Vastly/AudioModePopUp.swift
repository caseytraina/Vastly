//
//  AudioModePopUp.swift
//  Vastly
//
//  Created by Casey Traina on 11/18/23.
//

import SwiftUI

struct AudioModePopUp: View {
    
    @Binding var audioPopupShown: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .opacity(0.4)
            VStack {
                
                Spacer()
                if let uiImage = UIImage(named: "headphones") {
                    Image(uiImage: uiImage)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                
                
                Spacer()
                
                MyText(text: "Play Vastly", size: 24, bold: true, alignment: .center, color: .gray)
                    .brightness(0.3)
                MyText(text: "in your pocket", size: 24, bold: true, alignment: .center, color: .accentColor)
                
                Spacer()
                MyText(text: "Listening Mode Activated", size: 18, bold: true, alignment: .center, color: .white)
                Spacer()
            }
            .opacity(1)
            .frame(width: screenSize.width * 0.8, height: screenSize.height * 0.5)
            .background(
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(.linearGradient(colors: [.accentColor, .black, .black], startPoint: .topLeading, endPoint: .bottom))
                .opacity(1)
            )
        }
        .onTapGesture {
            audioPopupShown.toggle()
        }
        .highPriorityGesture(TapGesture()
            .onEnded{
                withAnimation {
                    audioPopupShown.toggle()
                }
            })
        }
}

//#Preview {
//    AudioModePopUp()
//}
