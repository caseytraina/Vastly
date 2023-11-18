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
                
                MyText(text: "Play Vastly", size: 24, bold: true, alignment: .center, color: .gray)
                    .brightness(0.3)
                MyText(text: "in your pocket", size: 24, bold: true, alignment: .center, color: .accentColor)
                
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
