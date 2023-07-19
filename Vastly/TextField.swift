//
//  TextField.swift
//  Vastly
//
//  Created by Casey Traina on 5/21/23.
//

import Foundation
import SwiftUI

struct GradientTextFieldBackground: TextFieldStyle {
    
    let systemImageString: String
    
    // Hidden function to conform to this protocol
    func _body(configuration: TextField<Self._Label>) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5.0)
                .stroke(
                    LinearGradient(
                        colors: [
                            .accentColor,
                            .accentColor,
                            Color("BackgroundColor")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 50)
            
            HStack {
                Image(systemName: systemImageString)
                    .foregroundColor(Color.white)
                // Reference the TextField here
                configuration
            }
            .padding(.leading)
            .foregroundColor(.white)
        }
    }
}
