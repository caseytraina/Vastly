//
//  AuthorInfoView.swift
//  Vastly
//
//  Created by Casey Traina on 7/28/23.
//

import SwiftUI

struct AuthorInfoView: View {
    
    var video: Video
    
    @Binding var authorButtonTapped: Bool
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                
                ScrollView {
                    VStack(alignment: .leading) {
                        //                    HStack {
                        MyText(text: "About this clip:", size: geo.size.width * 0.04, bold: true, alignment: .leading, color: .white)
                        
                        //                        Spacer()
                        //                    }
                        MyText(text: video.bio, size: geo.size.width * 0.04, bold: false, alignment: .leading, color: Color("AccentGray"))
                            .lineLimit(12)
                        HStack {
                            MyText(text: "About this podcast:", size: geo.size.width * 0.04, bold: true, alignment: .leading, color: .white)
                            Spacer()
                        }
                        MyText(text: video.author.bio ?? "", size: geo.size.width * 0.04, bold: false, alignment: .leading, color: Color("AccentGray"))
                            .lineLimit(12)
                        
                    }
                }
                HStack {
                    Spacer()
                    if video.author.website != "" {
                        
                        Button(action: {
                            openURL(video.author.website ?? "")
                        }) {
                            Image(systemName: "link.circle")
                                .foregroundColor(.white)
                            //                        .frame(width: geo.size.width * 0.075, height: geo.size.width * 0.075)
                                .font(.system(size: screenSize.width * 0.09, weight: .medium))
                                .padding(.trailing, 10)
                        }
                        
                        

                    }
                    if video.author.spotify != "" {
                        
                        Button(action: {
                            openURL(video.author.spotify ?? "")
                        }) {
                            Image("spotify")
                                .resizable()
                                .frame(width: geo.size.width * 0.09, height: geo.size.width * 0.09)
                                .padding(.trailing, 10)
                        }
                    }
                    if video.author.apple != "" {
                        
                        Button(action: {
                            openURL(video.author.apple ?? "")
                        }) {
                            Image("applePodcasts")
                                .resizable()
                                .frame(width: geo.size.width * 0.09, height: geo.size.width * 0.09)
                                .padding(.trailing, 10)
                        }
                    }
                }
                .padding(.trailing, 20)
            }
        }
    }
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        UIApplication.shared.open(url)
    }
}

//struct AuthorInfoView_Previews: PreviewProvider {
//
//    static var previews: some View {
//        AuthorInfoView(video: EMPTY_VIDEO)
//    }
//}
