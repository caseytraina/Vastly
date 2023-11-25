//
//  SeeMoreText.swift
//  Vastly
//
//  Created by Casey Traina on 10/24/23.
//

import SwiftUI

import SwiftUI

struct SeeMoreText: View {
    var text: String
    var size: CGFloat
    var bold: Bool
    var alignment: TextAlignment
    var color: Color
    @Binding var expanded: Bool
    
    @State var expandedString = "see more"
    
    init(text: String, size: CGFloat, bold: Bool, alignment: TextAlignment, color: Color, expanded: Binding<Bool>) {
        self.size = size
        self.bold = bold
        self.alignment = alignment
        self.text = text
        self.color = color
        self._expanded = expanded

    }
    // A generalized text since Apple doesn't support a default text functionality
    // Allows user to input a string, font size, bold/unbold, and alignment
    var body: some View {
        Text("\(text) **\(expandedString)**")
            .foregroundColor(color)
            .font(Font.custom(bold ? "CircularStd-Bold" : "CircularStd-Book", size: size))
            .truncationMode(.middle)
            .multilineTextAlignment(alignment)
            .lineLimit(expanded ? 8 : 2)
            .onChange(of: expanded) { newExpanded in
                if newExpanded {
                    expandedString = "see less"
                } else {
                    expandedString = "see more"
                }
                
            }

    }
}
