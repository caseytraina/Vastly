//
//  PasswordPromptView.swift
//  Vastly
//
//  Created by Casey Traina on 5/21/23.
//

import SwiftUI

struct PasswordPromptView: View {
    
    @Binding var name: String
    @Binding var email: String
    @Binding var password: String
    
    @EnvironmentObject private var authModel: AuthViewModel
//    @EnvironmentObject var viewModel: VideoViewModel

    var body: some View {

        GeometryReader { geo in
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                VStack {
                    MyText(text: "Vastly", size: geo.size.width * 0.075, bold: true, alignment: .center, color: .white)
                    Spacer()
                    HStack {
                        MyText(text: "Password", size: geo.size.width * 0.05, bold: false, alignment: .leading, color: .white)
                            .padding(.leading)
                        Spacer()
                    }
                    SecureField("Password", text: $password)
                        .foregroundColor(.white)
                        .font(Font.custom("CircularStd-Bold", size: geo.size.width * 0.05))
                        .textFieldStyle(GradientTextFieldBackground(systemImageString: "key"))
                        .frame(maxWidth: screenSize.width * 0.9)
                        .padding(.horizontal)
                        .accentColor(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    MyText(text: "Password must be at least 6 characters long", size: geo.size.width * 0.04, bold: false, alignment: .center, color: passwordIsLong() ? .green : .red)
//                    MyText(text: "Password must contain at least one number", size: geo.size.width * 0.04, bold: false, alignment: .center, color: passwordContainsNum() ? .green : .red)

                    NavigationLink(destination: PasswordConfirmView(name: $name, email: $email, password: $password)
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
                    .disabled(!passwordFulfilled())
                    .padding()
                    
                    Spacer()
                } // MAKE SURE NUMBER IN PASSWORD
            }
        }
    }
    
    private func passwordIsLong() -> Bool {
        return (password.count >= 6)
    }
    
    private func passwordContainsNum() -> Bool {
        var result = false
        
        for i in 0..<10 {
            if password.contains("\(i)") {
                result = true
            }
        }

        return result
    }
    
    private func passwordFulfilled() -> Bool {
        return (passwordIsLong())
//        return (passwordIsLong() && passwordIsLong())
    }
    
}

//struct PasswordPromptView_Previews: PreviewProvider {
//    static var previews: some View {
//        PasswordPromptView()
//    }
//}
