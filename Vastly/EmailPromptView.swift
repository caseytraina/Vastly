//
//  EmailPromptView.swift
//  Vastly
//
//  Created by Casey Traina on 5/21/23.
//

import SwiftUI

struct EmailPromptView: View {
    
    @Binding var name: String
    @Binding var email: String
    @Binding var password: String

    @EnvironmentObject private var authModel: AuthViewModel

    var body: some View {

        GeometryReader { geo in
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                VStack {
                    MyText(text: "Vastly", size: geo.size.width * 0.075, bold: true, alignment: .center, color: .white)
                    Spacer()
                    HStack {
                        MyText(text: "Email", size: geo.size.width * 0.05, bold: false, alignment: .leading, color: .white)
                            .padding(.leading)
                        Spacer()
                    }
                    TextField("Email", text: $email)
                        .foregroundColor(.white)
                        .font(Font.custom("CircularStd-Bold", size: geo.size.width * 0.05))
                        .textFieldStyle(GradientTextFieldBackground(systemImageString: "envelope"))
                        .frame(maxWidth: screenSize.width * 0.9)
                        .padding(.horizontal)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    NavigationLink(destination: PasswordPromptView(name: $name, email: $email, password: $password)
                        .environmentObject(authModel)
//                        .environmentObject(viewModel)
                    ) {
                        Image(systemName: "arrow.right")
                            .padding(.vertical, 15)
                            .padding(.horizontal, 30)
                            .foregroundColor(.white)
                            .background(name.isEmpty ? Color("AccentGray") : Color.accentColor)
                            .cornerRadius(10.0)
                    }
                    .padding()
                    .disabled(!ifIsEmail())
                    
                    Spacer()
                    
                    
                    
                    
                }
            }
        }


    }
    
    private func ifIsEmail() -> Bool {
        if email.contains("@") && email.contains(".") {
            return true
        } else {
            return false
        }
    }
    
    
}

//struct EmailPromptView_Previews: PreviewProvider {
//    static var previews: some View {
//        EmailPromptView()
//    }
//}
