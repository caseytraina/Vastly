//
//  ChooseTagsView.swift
//  Vastly
//
//  Created by Casey Traina on 8/22/23.
//

import SwiftUI

let INTERESTS = [
    "Growth",
    "Private Equity",
    "Investing",
    "Tech Industry",
    "Management",
    "Product",
    "Macro",
    "Strategy",
    "Monetary Policy",
    "Machine Learning",
    "Career",
    "Economics",
    "Innovation",
    "Venture Capital",
    "Learning",
]

struct ChooseTagsView: View {
    
    @Binding var name: String
    @Binding var credential: String
    @Binding var password: String
    
    @State var selected: [String] = []
    
    @EnvironmentObject private var authModel: AuthViewModel
    
    @State var isHidden = true
    @State var hiddenText = ""
    
    let columns: [GridItem] = [
        GridItem(.adaptive(minimum: screenSize.width * 0.3, maximum: screenSize.width * 0.8), spacing: 30)
    ]//Array(repeating: .init(.adaptive(minimum: screenSize.width * 0.3), spacing: 20), count: 3 )
    
    var typeOfAccount: AccountType
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                VStack(alignment: .leading) {
                    HStack {
                        Spacer()
                        MyText(text: "Vastly", size: geo.size.width * 0.075, bold: true, alignment: .center, color: .white)
                            .padding(.bottom)
                        Spacer()
                    }
                    Spacer()
                    MyText(text: "What are you interested in?", size: geo.size.width * 0.06, bold: false, alignment: .leading, color: .white)
                    MyText(text: "Choose at least three before moving on.", size: geo.size.width * 0.04, bold: true, alignment: .leading, color: Color("AccentGray"))
                    Spacer()
                    ScrollView {
                        TagsView(items: INTERESTS, selected: $selected)
//                            .frame( height: screenSize.height * 0.5)
                    }
                    Spacer()
                    if !isHidden {
                        MyText(text: hiddenText, size: geo.size.width * 0.04, bold: false, alignment: .center, color: .red)
                    }
                    HStack {
                        Spacer()
//                        Button(action: createAccount) {
                            
                            
                        NavigationLink(destination: PhoneLogin(phone: $credential, name: $name, selected: $selected, flow: .signUp)
                            .environmentObject(authModel)
    //                        .environmentObject(viewModel)
                        ) {
                            
                            Image(systemName: "arrow.right")
                                .padding(.vertical, 15)
                                .padding(.horizontal, 30)
                                .foregroundColor(.white)
                                .background(selected.count >= 3 ? Color.accentColor : Color("AccentGray"))
                                .cornerRadius(10.0)
                        }
                        .padding()
                        .disabled(selected.count < 3)
                    }

//                    }
                }
                .padding(.leading)
            }
        }
    }
    

    
}

//struct ChooseTagsView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChooseTagsView()
//    }
//}
