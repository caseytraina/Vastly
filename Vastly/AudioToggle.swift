//
//  AudioToggle.swift
//  Vastly
//
//  Created by Casey Traina on 7/27/23.
//

import SwiftUI

struct AudioToggleStyle: ToggleStyle {
    var onImage = "video.fill"
    var offImage = "headphones"
    
    var color: Color
    
 
    func makeBody(configuration: Configuration) -> some View {
 
        HStack {
            configuration.label
            MyText(text: "Watch", size: 18, bold: true, alignment: .center, color: configuration.isOn ? .accentColor : .gray)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .brightness(configuration.isOn ? 0 : 0.3)
                .background(
                RoundedRectangle(cornerRadius: 100)
                    .foregroundStyle(configuration.isOn ? Color.accentColor : .clear)
                    .brightness(configuration.isOn ? 0.5 : 0)
                )
            MyText(text: "Listen", size: 18, bold: true, alignment: .center, color: configuration.isOn ? .gray : .accentColor)
                .brightness(configuration.isOn ? 0.3 : 0)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 100)
                        .foregroundStyle(configuration.isOn ? .clear : Color.accentColor)
                        .brightness(configuration.isOn ? 0 : 0.5)
                )
        }
        .overlay(
        RoundedRectangle(cornerRadius: 100)
            .stroke(.white, lineWidth: 2)
        )
        .highPriorityGesture(TapGesture()
            .onEnded{
                withAnimation(.spring()) {
                    configuration.isOn.toggle()
                }
        })
        

        
    }
}

struct AudioToggleView: View {
    @State var toggleOn = true

    var body: some View {
        Toggle(isOn: $toggleOn) {
//            Text("Light/Dark mode")
//                .foregroundColor(.black)
        }
        .toggleStyle(AudioToggleStyle(color: .accentColor))
    }
}

struct AudioToggle_Previews: PreviewProvider {
    static var previews: some View {
        AudioToggleView()
    }
}
