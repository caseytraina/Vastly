//
//  LogInView.swift
//  Vastly
//
//  Created by Casey Traina on 5/20/23.
//

import SwiftUI

struct LogInView: View {
    
    @Binding var email: String
    @Binding var password: String
    @EnvironmentObject private var authModel: AuthViewModel
//    @EnvironmentObject var viewModel: VideoViewModel

    @State var successful = true
    
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
                        .autocapitalization(.none)
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
                        .autocapitalization(.none)
                        .onSubmit {
                            signIn()
                        }
                    if !successful {
                        MyText(text: "Username or password is incorrect.", size: geo.size.width * 0.04, bold: false, alignment: .center, color: .red)
                    }
                    
                    
                    NavigationLink(destination: {
                        ForgotPasswordView(email: $email)
                    }, label: {
                        MyText(text: "Forgot Password?", size: geo.size.width * 0.04, bold: true, alignment: .center, color: .white)
                    })
                    .padding()
                    
                    Button(action: signIn) {
                        MyText(text: "Sign In", size: geo.size.width * 0.04, bold: true, alignment: .center, color: .white)
                            .padding(10)
                            .background(ifIsEmail() ? Color.accentColor : Color("AccentGray"))
                            .cornerRadius(10.0)
                    }
                    .padding()
                    .disabled(!ifIsEmail() || password.isEmpty)
                    
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
    
    private func signIn() {
                
        Task {
            do {
                try await authModel.signIn(email: email, password: password)
                successful = true
            } catch {
                print(error)
                successful = false
            }
        }
    }
    
}
//
//struct LogInView_Previews: PreviewProvider {
//    static var previews: some View {
//        LogInView()
//    }
//}
