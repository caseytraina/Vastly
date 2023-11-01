//
//  VideoLoadingView.swift
//  Vastly
//
//  Created by Casey Traina on 5/21/23.
//

import SwiftUI

struct VideoLoadingView: View {
    
    @State var isAnimating = false
    var body: some View {

        GeometryReader { geo in
            ZStack {
                Color("BackgroundColor")
                VStack {
                    MyText(text: "Vastly", size: geo.size.width * 0.05, bold: true, alignment: .center, color: .accentColor)
//                    MyText(text: "We'll be right with you", size: geo.size.width * 0.03, bold: false, alignment: .center, color: Color("AccentGray"))
                    MyText(text: "Loading...", size: geo.size.width * 0.05, bold: true, alignment: .center, color: .white)
                }
            }
        }
        .padding(0)
        .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
        
    }
}

struct VideoLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        VideoLoadingView()
    }
}
