//
//  MyText.swift
//  Vastly
//
//  Created by Casey Traina on 5/9/23.
//

import SwiftUI

struct MyText: View {
    var text: String
    var size: CGFloat
    var bold: Bool
    var alignment: TextAlignment
    var color: Color
    
    
    init(text: String, size: CGFloat, bold: Bool, alignment: TextAlignment, color: Color) {
        self.size = size
        self.bold = bold
        self.alignment = alignment
        self.text = text
        self.color = color

    }
    // A generalized text since Apple doesn't support a default text functionality
    // Allows user to input a string, font size, bold/unbold, and alignment
    var body: some View {
            Text(text)
                .foregroundColor(color)
                .font(Font.custom(bold ? "CircularStd-Bold" : "CircularStd-Book", size: size))
            //            .padding(.horizontal, 15)
//                .padding(.vertical, bold ? 5 : 0)
                .multilineTextAlignment(alignment)

    }
}

struct MyText_Previews: PreviewProvider {
    static var previews: some View {
        MyText(text: "hello", size: 24, bold: true, alignment: .center, color: .black)
    }
}
