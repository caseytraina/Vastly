//
//  NavBar.swift
//  Vastly
//
//  Created by Casey Traina on 10/16/23.
//

import SwiftUI

struct NavBar: View {
    
    @Binding var selected: Page
    
    var body: some View {
        GeometryReader { geo in
            HStack (alignment: .center) {
                HStack (alignment: .center) {
                    ForEach(Page.allCases, id: \.self) { page in
                        Spacer()
                        Button(action: {
                            selected = page
                        }, label: {
                            VStack (alignment: .center) {
                                
//                                Image(systemName: selected == page ? page.iconActive : page.iconInactive)
                                if let uiImage = UIImage(named: selected == page ? page.iconActive : page.iconInactive) {
                                    Image(uiImage: uiImage)
                                        .renderingMode(.template)
                                        .font(.system(size: 18))
                                        .foregroundColor(selected == page ? .accentColor : .gray)
                                        .brightness(0.3)
                                        .frame(width: 24, height: 20)
                                        .animation(.easeOut, value: selected)
                                        .transition(.opacity)
                                }
                                    
                                
                                MyText(text: page.title, size: geo.size.width * 0.03, bold: true, alignment: .center, color: selected == page ? .accentColor : .gray)
                                    .lineLimit(1)
                                    .brightness(0.3)
                                    .animation(.easeOut, value: selected)
                                    .transition(.opacity)
                            }
                        })
                        .padding()
                        
                    }
                    
                    Spacer()
                    
                }
                .frame(width: geo.size.width * 0.95, height: geo.size.height)
                
                
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(
                Rectangle()
                    .foregroundStyle(Color("BackgroundColor"))
                    .brightness(0.05)
            )
        }
        
        
    }
}
//
//#Preview {
//    NavBar()
//}
