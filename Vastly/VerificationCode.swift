//
//  VerificationCode.swift
//  Vastly
//
//  Created by Casey Traina on 8/25/23.
//

import SwiftUI
import iPhoneNumberField

enum PhoneSignInResult {
    case createdAccount
    case loggedIn
    case error
}

struct VerificationCode: View {
    
    @EnvironmentObject private var authModel: AuthViewModel
    
    @Binding var phone: String
    @Binding var code: String
    
    @State var isEditing = true
    @State var errorMessage = ""
    @State var isHidden = true
    
    @Binding var name: String
    @Binding var selected: [String]
    
    var body: some View {

        GeometryReader { geo in
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                VStack {
                    MyText(text: "Vastly", size: geo.size.width * 0.075, bold: true, alignment: .center, color: .white)
                    Spacer()
                    HStack {
                        MyText(text: "Verification Code", size: geo.size.width * 0.05, bold: false, alignment: .leading, color: .white)
                            .padding(.leading)
                        Spacer()
                    }
                    
                    TextField("000000", text: $code)
                        .foregroundColor(.white)
                        .frame(width: screenSize.width * 0.7, height: screenSize.height * 0.075)
                        .background(Color("BackgroundColor"))
                        .font(Font.custom("CircularStd-Bold", size: geo.size.width * 0.07))
//                        .textFieldStyle(GradientTextFieldBackground(systemImageString: "envelope"))
                        .textContentType(.oneTimeCode)
                        .cornerRadius(10)
                        .shadow(color: .accentColor , radius: 10)
                        .lineLimit(1)
                        .padding()
                        .autocapitalization(.none)
                        .onSubmit {
                            signIn()
                        }
                        .multilineTextAlignment(.center)
                        
                    Button(action: {
                        sendCode()
                    }, label: {
                        MyText(text: "Send New Code", size: geo.size.width * 0.04, bold: true, alignment: .center, color: .white)
                            .lineLimit(1)
                    })
                    
                    
                    
//
//                    iPhoneNumberField("000-000", text: $code, isEditing: $isEditing)
//                        .formatted(true)
//                        .font(UIFont(size: 30, weight: .bold, design: .rounded))
//                        .maximumDigits(6)
//                        .foregroundColor(Color.white)
//                        .clearButtonMode(.whileEditing)
//                        .onClear { _ in isEditing.toggle() }
//                        .padding()
//                        .background(Color("BackgroundColor"))
//                        .cornerRadius(10)
//                        .shadow(color: isEditing ? .accentColor : Color("AccentGray"), radius: 10)
//                        .padding()
//                        .onSubmit {
//                            signIn()
//                        }
//                        .multilineTextAlignment(.center)
//

                    if !isHidden {
                        MyText(text: errorMessage, size: geo.size.width * 0.04, bold: true, alignment: .leading, color: .red)
                            .padding(.horizontal)
                    }
                    
                    
//                    if !successful {
//                        MyText(text: "Username or password is incorrect.", size: geo.size.width * 0.04, bold: false, alignment: .center, color: .red)
//                    }
                    
                    
                    HStack {
                        Spacer()
                        Button(action: signIn) {
                            Image(systemName: "arrow.right")
                                .padding(.vertical, 20)
                                .padding(.horizontal, 40)
                                .foregroundColor(.white)
                                .background(code.count >= 6 ? .accentColor : Color("AccentGray"))
                                .cornerRadius(10.0)
                        }
                        .disabled(code.count < 6)
                        .padding()
                    }
                    
//                    Button(action: signIn) {
//                        MyText(text: "Sign In", size: geo.size.width * 0.04, bold: true, alignment: .center, color: .white)
//                            .padding(10)
//                            .background(ifIsEmail() ? Color.accentColor : Color("AccentGray"))
//                            .cornerRadius(10.0)
//                    }
//                    .paddin1
                    Spacer()
//                    NavigationLink(destination: {
////                        LogInView(phone: $email, password: $password)
//                    }, label: {
//                        MyText(text: "Forgot Password?", size: geo.size.width * 0.04, bold: true, alignment: .center, color: .white)
//                    })
//                    .padding()
                }
                .onChange(of: code) { newCode in
                    if newCode.count >= 6 {
                        signIn()
                    }
                }
            }
        }
    }
    
    private func signIn() {
        authModel.signInPhone(code: self.code) { result in
            if result == .createdAccount {
                createAccount()
            } else if result == .loggedIn {
                print("successfully logged in")
                Task {
                    await authModel.configureUser(phone)
                }
            } else {
                isHidden = false
                errorMessage = "An error occurred finding your account details."
                return
            }
            
            
        }
    }
    
    private func firstName() -> String {
        let nameArray = name.components(separatedBy: " ")
        
        return nameArray[0]
    }
    
    private func lastName() -> String {
        let nameArray = name.components(separatedBy: " ")
        
        if nameArray.count >= 2 {
            return nameArray[1]
        } else {
            return ""
        }
        
    }
    
    private func createAccount() {
        
        let first = firstName()
        let last = lastName()
                
        Task {
            do {
                await authModel.createUserInFirestore(typeOfUser: .PhoneNumber, credential: phone, firstName: first, lastName: last, videos: [], interests: selected)
                await authModel.configureUser(phone)
            } catch {
                print("Failed to create account: \(error)")
                isHidden = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func sendCode() {
        Task {
//            let realPhone = "+1\(phone)"
            await authModel.sendCodeTo(phone)
        }
    }
    
}

//struct VerificationCode_Previews: PreviewProvider {
//    static var previews: some View {
//        VerificationCode()
//    }
//}
