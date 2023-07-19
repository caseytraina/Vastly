//
//  ScrollingVStackModifier.swift
//  Vastly
//
//  Created by Casey Traina on 5/16/23.
//

import Foundation
import SwiftUI

//struct VerticalDragGesture: ViewModifier {
//    
//    
//    
//    @Binding var channel_index = 0
//    @Binding var video_index = 0
//    
//    func body(content: Content) -> some View {
//        content
//            .gesture(
//                DragGesture()
//                .onEnded({ gesture in
//                    if gesture.translation.height < -(screenSize.height/4) {
//                        withAnimation {
//                            
//                            if (channel_index < Channel.allCases.count && channel_index >= 0) {
//                                channel_index += 1
//                                proxy.scrollTo(channel_index, anchor: .top)
//                                activeChannel = Channel.allCases[channel_index]
//                            }
//                        }
//                        
//                    } else if gesture.translation.height > screenSize.height/4 {
//                        withAnimation {
//                            
//                            if (channel_index >= 1 && channel_index < Channel.allCases.count) {
//                                channel_index -= 1
//                                proxy.scrollTo(channel_index, anchor: .top)
//                                activeChannel = Channel.allCases[channel_index]
//                            }
//                        }
//                    }
//                    
//                    offset.height = 0
//                    
//                })
//                .onChanged({ gesture in
//                    offset.height = gesture.translation.height
//                }))
//    }
//    
//
//}
