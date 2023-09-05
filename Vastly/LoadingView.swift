//
//  LoadingView.swift
//  Vastly
//
//  Created by Casey Traina on 5/14/23.
//

import SwiftUI


struct LoadingView: View {
    
    @State var text = "Explore the podcast universe"
    @State private var currentIndex = 0
    
    
    let messages = [
        "Explore the podcast universe",
        "Explore the podcast universe.",
        "Explore the podcast universe..",
        "Explore the podcast universe..."
    ]
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            Group {
                Text("Vastly")
                    .foregroundColor(Color.white)
                    .font(Font.custom("CircularStd-Bold", size: geo.size.width * 0.1))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .position(x: geo.size.width/2, y: geo.size.height/3)
                Text(text)
                    .foregroundColor(Color.accentColor)
                    .font(Font.custom("CircularStd-Book", size: geo.size.width * 0.05))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .position(x: geo.size.width/2, y: geo.size.height/2)
//                    .transition(.opacity)
//                    .animation(.default)
            }
        }
        .onReceive(timer) { _ in
            currentIndex = (currentIndex + 1) % messages.count
            text = messages[currentIndex]
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
