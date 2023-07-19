//
//  VideoFailedView.swift
//  Vastly
//
//  Created by Casey Traina on 7/26/23.
//

import SwiftUI

struct VideoFailedView: View {
    
    var body: some View {

        GeometryReader { geo in
            ZStack {
                Color("BackgroundColor")
                VStack {
                    MyText(text: "Vastly", size: geo.size.width * 0.05, bold: true, alignment: .center, color: .accentColor)
                    MyText(text: "This video can't be found!", size: geo.size.width * 0.03, bold: false, alignment: .center, color: .white)
//                    MyText(text: "We'll be right with you", size: geo.size.width * 0.03, bold: false, alignment: .center, color: Color("AccentGray"))
                    Image(systemName: "x.square")
                        .foregroundColor(Color.red)
                        .font(.system(size: geo.size.width * 0.05, weight: .light))
                        .padding()


                }
            }
        }
        .padding(0)
        .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
        
    }
}

struct VideoFailedView_Previews: PreviewProvider {
    static var previews: some View {
        VideoFailedView()
    }
}
