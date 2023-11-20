//
//  PasswordConfirmView.swift
//  Vastly
//
//  Created by Casey Traina on 5/21/23.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct PasswordConfirmView: View {
    
    @State var passwordConfirm = ""
    
    @Binding var name: String
    @Binding var email: String
    @Binding var password: String
    @State var isHidden = true
    @State var hiddenText = ""
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
                        MyText(text: "Verify Password", size: geo.size.width * 0.05, bold: false, alignment: .leading, color: .white)
                            .padding(.leading)
                        Spacer()
                    }
                    SecureField("Password", text: $passwordConfirm)
                        .foregroundColor(.white)
                        .font(Font.custom("CircularStd-Bold", size: geo.size.width * 0.05))
                        .textFieldStyle(GradientTextFieldBackground(systemImageString: "key"))
                        .frame(maxWidth: screenSize.width * 0.9)
                        .padding(.horizontal)
                        .accentColor(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    MyText(text: "Passwords must match", size: geo.size.width * 0.04, bold: false, alignment: .center, color: password == passwordConfirm ? .green : .red)
                    if !isHidden {
                        MyText(text: hiddenText, size: geo.size.width * 0.04, bold: false, alignment: .center, color: .red)
                    }


                    NavigationLink(destination: ChooseTagsView(name: $name, credential: $email, password: $password, typeOfAccount: .Email)
                        .environmentObject(authModel)
//                        .environmentObject(viewModel)
                    ) {
                        Image(systemName: "arrow.right")
                            .padding(.vertical, 15)
                            .padding(.horizontal, 30)
                            .foregroundColor(.white)
                            .background(password != passwordConfirm ? Color("AccentGray") : Color.accentColor)
                            .cornerRadius(10.0)
                    }
//                    .navigationTitle("Title")
//                    .navigationBarTitleDisplayMode(.large)
                    .disabled(password != passwordConfirm)
                    .padding()
                    
//                    Button(action: createAccount) {
//                        MyText(text: "Create account", size: geo.size.width * 0.04, bold: true, alignment: .center, color: .white)
//                            .padding(10)
//                            .background(password == passwordConfirm ? Color.accentColor : Color("AccentGray"))
//                            .cornerRadius(10.0)
//                    }
//                    .disabled(password != passwordConfirm)
                    
                    Spacer()
                }
            }
        }
    }
    

    
    
}

//struct PasswordConfirmView_Previews: PreviewProvider {
//    static var previews: some View {
//        PasswordConfirmView()
//    }
//}
