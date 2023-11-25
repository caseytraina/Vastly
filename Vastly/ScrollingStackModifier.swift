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
