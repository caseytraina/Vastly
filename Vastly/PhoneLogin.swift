//
//  SwiftUIView.swift
//  Vastly
//
//  Created by Casey Traina on 8/25/23.
//

import SwiftUI
import iPhoneNumberField

enum Flow {
    case signUp
    case logIn
}

struct PhoneLogin: View {
    
    @Binding var phone: String
//    var password: String = ""
    @State var code: String = ""
    @EnvironmentObject private var authModel: AuthViewModel
//    @EnvironmentObject var viewModel: VideoViewModel

    @State var successful = true
//    @State var isEditing = true
    @State var codeSent = false

    @Binding var name: String
    @Binding var selected: [String]
    
    @State var flow: Flow = .logIn
    
    @State var email = ""
    @State var password = ""

    var body: some View {

        GeometryReader { geo in
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                VStack {
                    MyText(text: "Vastly", size: geo.size.width * 0.075, bold: true, alignment: .center, color: .white)
                    Spacer()
                    HStack {
                        MyText(text: "Phone Number", size: geo.size.width * 0.05, bold: false, alignment: .leading, color: .white)
                            .padding(.leading)
                        Spacer()
                    }
                    
                    HStack {
                        Spacer()
                        MyText(text: "🇺🇸", size: geo.size.width * 0.1, bold: true, alignment: .center, color: .white)
                            .lineLimit(1)
//                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(Color("BackgroundColor"))
                                .shadow(color: .accentColor, radius: 10)
                                .frame(width: geo.size.width * 0.15, height: geo.size.width * 0.15)
                                        
                            )
                        
                        TextField("000-000-0000", text: $phone)
                            .foregroundColor(.white)
                            .frame(height: geo.size.width * 0.15)
                            .background(Color("BackgroundColor"))
                            .font(Font.custom("CircularStd-Bold", size: geo.size.width * 0.07))
    //                        .textFieldStyle(GradientTextFieldBackground(systemImageString: "envelope"))
                            .textContentType(.oneTimeCode)
                            .cornerRadius(10)
                            .shadow(color: .accentColor , radius: 10)
                            .lineLimit(1)
                            .frame(maxWidth: screenSize.width * 0.75)
                            .padding()
                            .autocapitalization(.none)
                            .onSubmit {
                                phone = cleanNumber(phone)
                                sendCode()
                            }

                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: geo.size.width * 0.9)
                    .onChange(of: phone) { newPhone in
                        if newPhone.count == 3 {
                            phone = newPhone + "-"
                        } else if newPhone.count == 7 {
                            phone = newPhone + "-"

                        }
                    }
                    
//                    iPhoneNumberField("(000) 000-0000", text: $phone, formatted: true)
//                        .autofillPrefix(true)
//                        .flagHidden(false)
//                        .flagSelectable(false)
//                        .font(UIFont(size: 30, weight: .bold, design: .rounded))
//                        .maximumDigits(10)
//                        .foregroundColor(Color.white)
//                        .clearButtonMode(.whileEditing)
////                        .onClear { _ in isEditing.toggle() }
////                        .formatted(true)
////                        .previewPrefix(true)
////                        .prefixHidden(false)
//                        .accentColor(.accentColor)
//                        .padding()
//                        .background(Color("BackgroundColor"))
//                        .cornerRadius(10)
//                        .shadow(color: .accentColor, radius: 10)
//                        .padding()
//                        .onSubmit {
//                            phone = cleanNumber(phone)
//                            sendCode()
//                        }
                    
                    
                    
                    if !successful {
                        MyText(text: "Username or password is incorrect.", size: geo.size.width * 0.04, bold: false, alignment: .center, color: .red)
                    }
                    NavigationLink(destination: VerificationCode(phone: $phone, code: $code, name: $name, selected: $selected)
                                            .environmentObject(authModel),
                                           isActive: $codeSent,
                                           label: {
                                               EmptyView()
                    })
                    
                    if (flow == .logIn) {
                        NavigationLink(destination: LogInView(email: $email, password: $password)
                            .environmentObject(authModel)
                                       //                        .environmentObject(viewModel)
                        ) {
                            MyText(text: "Sign in with Email Instead", size: geo.size.width * 0.04, bold: true, alignment: .center, color: .white)
                                .lineLimit(2)
                        }
                        //                    .navigationTitle("Title")
                        //                    .navigationBarTitleDisplayMode(.large)
                        .padding()
                    }
                    
                        Button(action: {
    //                        phone = "+1\(phone)"
                            print("clicked")
                            phone = cleanNumber(phone)
                            sendCode()
                        }) {
                                Image(systemName: "arrow.right")
                                    .padding(.vertical, 20)
                                    .padding(.horizontal, 40)
                                    .foregroundColor(.white)
                                    .background(phone.count >= 0 ? Color.accentColor : Color("AccentGray"))
                                    .cornerRadius(10.0)
                            }
                            .disabled(phone.count < 10)
                            .padding()
                        
//                    })

                
                    Spacer()
//
                }
            }
            
        }
    }

    
    private func sendCode() {
        Task {
//            let realPhone = "+1\(phone)"
            await authModel.sendCodeTo(phone)
            codeSent = true
        }
    }
    
    private func cleanNumber(_ number: String) -> String {
        
        var result = number
        if !result.contains("+1") {
            result = "+1\(result)"
        }
        result = result.replacingOccurrences(of: "(", with: "")
        result = result.replacingOccurrences(of: ")", with: "")
        result = result.replacingOccurrences(of: " ", with: "")
        result = result.replacingOccurrences(of: "-", with: "")
        return result
    }
    
}
//
//struct PhoneLogin_Previews: PreviewProvider {
//    static var previews: some View {
//        PhoneLogin()
//    }
//}
