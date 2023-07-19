//
//  ScrollingStackModifier.swift
//  Vastly
//
//  Created by Casey Traina on 5/9/23.
//

import SwiftUI

struct ScrollingHStackModifier: ViewModifier {
    
    @State private var scrollOffset: CGFloat
    @State private var dragOffset: CGFloat
    @Binding var current: Int

    @Binding var items: Int
    var itemWidth: CGFloat
    var itemSpacing: CGFloat
    
    init(items: Binding<Int>, itemWidth: CGFloat, itemSpacing: CGFloat, current: Binding<Int>) {
        self._items = items
        self.itemWidth = itemWidth
        self.itemSpacing = itemSpacing
        
        // Calculate Total Content Width
        let contentWidth: CGFloat = CGFloat(items.wrappedValue) * itemWidth + CGFloat(items.wrappedValue - 1) * itemSpacing
        let screenWidth = UIScreen.main.bounds.width
        
        // Set Initial Offset to first Item
        let initialOffset = (contentWidth/2.0) - (screenWidth/2.0) + ((screenWidth - itemWidth) / 2.0)
//        let initialOffset = CGFloat(items/2) * itemWidth //- (screenWidth/2)

        self._scrollOffset = State(initialValue: initialOffset)
        self._dragOffset = State(initialValue: 0)
        self._current = current

    }
    
    func body(content: Content) -> some View {
        content
            .id(items)
            .offset(x: scrollOffset + dragOffset, y: 0)
            .onChange(of: current) { newcurrent in
                
                DispatchQueue.global(qos: .userInitiated).async {

                    let contentWidth: CGFloat = CGFloat(items) * itemWidth

                    let index = items - current - 1

                    // Set final offset (snapping to item)
                    let itemOffset = CGFloat(index) * itemWidth
                    let halfContentWidth = contentWidth / 2.0
                    let halfScreenWidth = itemWidth / 2.0

                    let newOffset = itemOffset - halfContentWidth + halfScreenWidth

                    // Animate snapping

                    DispatchQueue.global(qos: .userInteractive).async {

                        withAnimation(.linear(duration: 0.125)) {
                            scrollOffset = newOffset
                        }
                    }
                }
            }
            .onChange(of: items) { newItems in
                // Calculate Total Content Width
                let contentWidth: CGFloat = CGFloat(newItems) * itemWidth + CGFloat(newItems - 1) * itemSpacing
                let screenWidth = UIScreen.main.bounds.width

                // Set Initial Offset to first Item
                let initialOffset = (contentWidth/2.0) - (screenWidth/2.0) + ((screenWidth - itemWidth) / 2.0)

                let itemOffset = CGFloat(current) * itemWidth
//                withAnimation {
                    scrollOffset = initialOffset - itemOffset//+ CGFloat(current) * itemWidth
//                }
//                }
            }
            .onAppear {
                let contentWidth: CGFloat = CGFloat(items) * itemWidth + CGFloat(items - 1) * itemSpacing
                let screenWidth = UIScreen.main.bounds.width

                // Set Initial Offset to first Item
                let initialOffset = (contentWidth/2.0) - (screenWidth/2.0) + ((screenWidth - itemWidth) / 2.0)

                let itemOffset = CGFloat(current) * itemWidth
                withAnimation {
                    scrollOffset = initialOffset - itemOffset//+ CGFloat(current) * itemWidth
                }
            }

            .gesture(DragGesture()
                .onChanged({ event in
                    dragOffset = event.translation.width
                })
                .onEnded({ event in
                    // Calculate new current index
                    
                    DispatchQueue.global(qos: .userInitiated).async {

                        
                        let vel = event.predictedEndTranslation.width
                        let distance = event.translation.width
                        
                        if vel <= -itemWidth/2 || distance <= -itemWidth/2 {
                            if current+1 <= items {
                                current += 1
                            }
                        } else if vel >= itemWidth/2 || distance >= itemWidth/2 {
                            if current > 0 {
                                current -= 1
                            }
                        }
                        
                        // Calculate new offset based on updated current
                        let contentWidth: CGFloat = CGFloat(items) * itemWidth
                        let index = items - current - 1
                        
                        // Set final offset (snapping to item)
                        let itemOffset = CGFloat(index) * itemWidth
                        let halfContentWidth = contentWidth / 2.0
                        let halfScreenWidth = itemWidth / 2.0
                        
                        let newOffset = itemOffset - halfContentWidth + halfScreenWidth
                        
                        // Animate snapping
                        withAnimation(.easeOut(duration: 0.125)) {
                            scrollOffset = newOffset
                            dragOffset = 0
                        }
                    }
                })
        )
        
    }
}







// Calculate Total Content Width
//                let contentWidth: CGFloat = CGFloat(newItems) * itemWidth + CGFloat(newItems - 1) * itemSpacing
//                let screenWidth = UIScreen.main.bounds.width
//
//                // Set Initial Offset to first Item
//                let initialOffset = (contentWidth/2.0) - (screenWidth/2.0) + ((screenWidth - itemWidth) / 2.0)
//
//                // Update the state variables
//                self.scrollOffset = initialOffset
//                self.dragOffset = 0
                
//                // Calculate Total Content Width
////                let contentWidth: CGFloat = CGFloat(newItems) * itemWidth + CGFloat(newItems - 1) * itemSpacing
//                let screenWidth = UIScreen.main.bounds.width
//
//                // Set Initial Offset to first Item
////                let initialOffset = (contentWidth/2.0) - (screenWidth/2.0) + ((screenWidth - itemWidth) / 2.0)
//        //        let initialOffset = CGFloat(items/2) * itemWidth //- (screenWidth/2)
//
//
//                let index = items - current - 1
//
//                // Set final offset (snapping to item)
//                let itemOffset = CGFloat(index) * itemWidth
////                let halfContentWidth = contentWidth / 2.0
//                let halfScreenWidth = itemWidth / 2.0
//
////                let newOffset = (halfContentWidth - halfScreenWidth + (CGFloat(current) * itemWidth))//itemOffset - halfContentWidth + halfScreenWidth
//
//
//                let contentWidth: CGFloat = CGFloat(newItems) * itemWidth
//                let initOffset = newItems % 2 == 0 ? contentWidth/2 - 0.5*itemWidth : contentWidth/2
//
//                let newOffset = contentWidth / 2 - itemWidth/2 + CGFloat(current) * itemWidth
//
//                DispatchQueue.global(qos: .userInteractive).async {
//
//                    withAnimation(.linear(duration: 0.125)) {
//                        self.scrollOffset = newOffset
//                        self.dragOffset = 0
//                    }
//                }




//                let contentWidth: CGFloat = CGFloat(newItems) * itemWidth
//                let index = newItems - current
//
//                // Set final offset (snapping to item)
//                let itemOffset = CGFloat(index) * itemWidth
//                let halfContentWidth = contentWidth / 2.0
//                let halfScreenWidth = itemWidth / 2.0
//
//                let newOffset = itemOffset - halfContentWidth + halfScreenWidth
//
//                // Animate snapping
//                withAnimation(.easeOut(duration: 0.125)) {
//                    scrollOffset = newOffset
//                    dragOffset = 0
//                }
