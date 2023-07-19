//
//  ForgotPasswordView.swift
//  Vastly
//
//  Created by Casey Traina on 8/3/23.
//

import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    
    @Binding var email: String
//    @EnvironmentObject private var authModel: AuthViewModel
    
    @State private var alertMessage: String = "Please check your email for instructions"
    @State private var showAlert: Bool = false
        
    var body: some View {

        GeometryReader { geo in
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                VStack {
                    MyText(text: "Forgot Password", size: geo.size.width * 0.06, bold: true, alignment: .center, color: .white)
                        .padding()
                    Spacer()

                    TextField("Email", text: $email)
                        .foregroundColor(.white)
                        .font(Font.custom("CircularStd-Bold", size: geo.size.width * 0.05))
                        .textFieldStyle(GradientTextFieldBackground(systemImageString: "envelope"))
                        .frame(maxWidth: screenSize.width * 0.9)
                        .padding(.horizontal)
                        .autocapitalization(.none)
                    Button(action: resetPassword) {
                        MyText(text: "Reset Password", size: geo.size.width * 0.04, bold: true, alignment: .center, color: .white)
                            .padding(10)
                            .background((email.count > 0) ? Color.accentColor : Color("AccentGray"))
                            .cornerRadius(10.0)
                    }
                    .padding()
                    .disabled(!(email.count > 0))
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Password Reset"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
                    Spacer()

                    
                }
                
            }
        }
    }
    
    private func resetPassword() {
        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = error.localizedDescription
                } else {
                    alertMessage = "Password reset email sent to \(email)"
                }
                showAlert = true
            }
        }
    }
    
}

//struct ForgotPasswordView_Previews: PreviewProvider {
//
//    static var previews: some View {
//        ForgotPasswordView()
//    }
//}
