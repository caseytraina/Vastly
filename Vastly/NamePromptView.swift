//
//  NamePromptView().swift
//  Vastly
//
//  Created by Casey Traina on 5/20/23.
//

import SwiftUI

struct NamePromptView: View {
    
    @Binding var name: String
    @Binding var phone: String
    @Binding var password: String
    
    var typeOfAccount: AccountType
    
    @EnvironmentObject private var authModel: AuthViewModel

    var body: some View {

        GeometryReader { geo in
//            NavigationView {
                ZStack {
                    Color("BackgroundColor")
                        .ignoresSafeArea()
                    VStack {
                        MyText(text: "Vastly", size: geo.size.width * 0.075, bold: true, alignment: .center, color: .white)
                        Spacer()
                        HStack {
                            MyText(text: "Full Name", size: geo.size.width * 0.05, bold: false, alignment: .leading, color: .white)
                                .padding(.leading)
                            Spacer()
                        }
                        TextField("Full Name", text: $name)
                            .foregroundColor(.white)
                            .font(Font.custom("CircularStd-Bold", size: geo.size.width * 0.05))
                            .textFieldStyle(GradientTextFieldBackground(systemImageString: "person"))
                            .frame(maxWidth: screenSize.width * 0.9)
                            .padding(.horizontal)
                            .autocapitalization(.words)


                        NavigationLink(destination: ChooseTagsView(name: $name, credential: $phone, password: $password, typeOfAccount: .PhoneNumber)
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
                    .disabled(name.isEmpty)
                        
                        Spacer()
                    }
                }
//            }
        }
    }
}

//struct NamePromptView_Previews: PreviewProvider {
//    
//    @State var name = "Casey"
//    @State var email = "casey@gmail.com"
//    @State var password = "123456"
//    
//    static var previews: some View {
//        CreateAccountView()
//    }
//}
