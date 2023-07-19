//
//  VideoThumbnailView.swift
//  Vastly
//
//  Created by Casey Traina on 8/1/23.
//

import SwiftUI

struct VideoThumbnailView: View {
    
    var video: Video
    
    @State var isAnimating = false
    
    var body: some View {

        GeometryReader { geo in
            
            
            ZStack {
                AsyncImage(url: getThumbnail(video: video)) { image in
                    image.resizable()
                        .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                        .blur(radius: 5)
                } placeholder: {
                    Color("BackgroundColor")
                        
                }
                VStack {
                    MyText(text: "Vastly", size: geo.size.width * 0.05, bold: true, alignment: .center, color: .accentColor)
                    //                    MyText(text: "We'll be right with you", size: geo.size.width * 0.03, bold: false, alignment: .center, color: Color("AccentGray"))
                    MyText(text: "Loading...", size: geo.size.width * 0.04, bold: true, alignment: .center, color: .white)
                        .padding()
                    
                    
                }
                
            }
        }
        .padding(0)
        .frame(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
        
    }
}

struct VideoThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
        VideoThumbnailView(video: EMPTY_VIDEO)
    }
}


private func getThumbnail(video: Video) -> URL? {
    
    var urlString = video.url?.absoluteString
    
    urlString = urlString?.replacingOccurrences(of: "?tr=f-auto", with: "/ik-thumbnail.jpg")
    
    return URL(string: urlString ?? "")
}
