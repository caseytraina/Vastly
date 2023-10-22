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
     
                Spacer()
     
                ZStack {
                    RoundedRectangle(cornerRadius: 100)
                        .fill(configuration.isOn ? Color("BackgroundColor") : Color("BackgroundColor"))
                        .overlay {
                            Circle()
                                .frame(width: screenSize.width * 0.055)
                                .foregroundColor(.white)

                                .offset(x: configuration.isOn ? -screenSize.width * 0.0375 : screenSize.width * 0.0375)
                        }
                        .frame(width: screenSize.width * 0.15, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 100)
                                .stroke(Color.white, lineWidth: 1)
                        )
                        .onTapGesture {
                            
                        }
                        .highPriorityGesture(TapGesture()
                            .onEnded{
                                withAnimation(.spring()) {
                                    configuration.isOn.toggle()
                                }
                            })
                    
                    ZStack {
                        Image(systemName: "video.fill")
                            .foregroundColor(configuration.isOn ? color : .white)
                            .font(.system(size: screenSize.width * 0.025, weight: .light))
                            .offset(x: -screenSize.width * 0.0375)
                            
    //                        .resizable()
    //                        .scaledToFill()

                        Image(systemName: "headphones")
                            .foregroundColor(configuration.isOn ? .white : color)
                            .font(.system(size: screenSize.width * 0.025, weight: .light))
                            .offset(x: screenSize.width * 0.0375)


    //                        .resizable()
    //                        .scaledToFill()
                    }
                    
                    
                }
            }
        
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
