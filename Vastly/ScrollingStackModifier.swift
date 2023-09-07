//
//  ScrollingStackModifier.swift
//  Vastly
//
//  Created by Casey Traina on 5/9/23.
//

import SwiftUI



struct HSnapScrolling: ViewModifier {
    
    @Binding var numItems: Int
    var itemWidth: Double
    
    @Binding var index: Int
    @Binding var dragOffset: Double
    
    @State var indexOffset = 0.0
    @State var startingOffset: Double?
    
    init(numItems: Binding<Int>, itemWidth: Double, index: Binding<Int>, dragOffset: Binding<Double>) {
        self._numItems = numItems
        self.itemWidth = itemWidth
        self._index = index
        self._dragOffset = dragOffset
        
        indexOffset = (CGFloat(index.wrappedValue) * itemWidth)
        
        let start = -CGFloat(numItems.wrappedValue)/2 * itemWidth + itemWidth/2
        self.startingOffset = start
        
        print("HERE ARE STARTING VALUES: \(start) + \(numItems)")
    }
    
    func body(content: Content) -> some View {
        content
            .offset(x: startingOffset ?? 0 - indexOffset + dragOffset)
            .onChange(of: index) { newIndex in
                withAnimation(.easeOut(duration: 0.125)) {
                    indexOffset = Double(newIndex) * itemWidth
                }
            }
            
    }
}

struct VSnapScrolling: ViewModifier {
    
    @Binding var numItems: Int
    var itemWidth: Double
    
    @Binding var index: Int
    @Binding var dragOffset: Double
    
    @State var indexOffset = 0.0
    @State var startingOffset: Double = 0.0

    init(numItems: Binding<Int>, itemWidth: Double, index: Binding<Int>, dragOffset: Binding<Double>) {
        self._numItems = numItems
        self.itemWidth = itemWidth
        self._index = index
        self._dragOffset = dragOffset
        
        indexOffset = (CGFloat(index.wrappedValue) * itemWidth)
        
        let start = -CGFloat(numItems.wrappedValue)/2 * itemWidth + itemWidth/2
        self.startingOffset = start
        
        print(start + indexOffset)
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: startingOffset - indexOffset + dragOffset)
            .onChange(of: index) { newIndex in
                withAnimation(.easeOut(duration: 0.125)) {
                    indexOffset = Double(newIndex) * itemWidth
                }
            }
    }
}

/*
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

 */
