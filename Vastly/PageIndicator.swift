//
//  PageIndicator.swift
//  Vastly
//
//  Created by Casey Traina on 7/20/23.
//

import SwiftUI

struct PageIndicator: View {
    
    @Binding var currentIndex: Int
    @State var firstShown = 0
    @State var lastShown = 100

    @State var page = 10
    
    @State var prev = 0
    
    var pageCount: Int
    var color: Color
    
    @Binding var channel: Channel

    var body: some View {
        VStack {
            HStack {
                
                if page > 6 {
                    ForEach(firstShown..<lastShown, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? color : Color("AccentGray"))
                            .frame(width: abs(8 - abs(CGFloat(index - currentIndex + 1))), height: abs(8 - abs(CGFloat(index - currentIndex))))
                            .transition(.opacity)
                            .animation(.default, value: currentIndex)
                            .animation(.default, value: firstShown)

                    }
                } else {
                    
                    
                    ForEach(0..<page, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? color : Color("AccentGray"))
                            .frame(width: 8, height: 8)
                            .transition(.opacity)
                            .animation(.default, value: currentIndex)
                    }
                }
            }
            .onChange(of: currentIndex) { newIndex in
                
                if newIndex >= 5 && newIndex > prev {
                    page += 1
                    firstShown += 1
                    lastShown += 1
                } else if newIndex >= 5 && newIndex < prev {
                    firstShown -= 1
                    lastShown -= 1
                }
                prev = newIndex
            }
            .onChange(of: channel) { newChannel in
                firstShown = 0
                lastShown = 100
                lastShown = pageCount > 6 ? 7 : pageCount
                page = pageCount
                prev = 0
            }
            
//            Button("Add") {
//                if currentIndex < 4 {
//                    currentIndex += 1
//                } else {
//                    currentIndex += 1
////                    pageCount += 1
//                    firstShown += 1
//                    lastShown += 1
//                }
//            }
            
        }
        .onAppear {
            lastShown = pageCount > 6 ? 7 : pageCount
            page = pageCount
        }
        
    }
}

//struct PageIndicator_Previews: PreviewProvider {
//    static var previews: some View {
//        PageIndicator()
//    }
//}
