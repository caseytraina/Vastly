//
//  FlowLayout.swift
//  Vastly
//
//  Created by Casey Traina on 8/23/23.
//

import SwiftUI
//import LoremSwiftum

//struct TestWrappedHStackView: View {
//    
//   // let words = ["Action", "Horror one", "🐇", "IT 2", "Comedy is good", "Adventure Park", "Kids", "Science Fiction", "Drama", "Romance", "ET", "Silicon Valley", "Fantasy", "Spotlight", "Facebook", "I know what you did last summer", "Money Ball", "Seinfeld", "Raymond", "Thriller movies are the best movies!", "IT 3"]
//    
////    let words = Lorem.words(100).split(separator: " ").map { String($0) }
//
//    var body: some View {
//        TagsView(items: INTERESTS)
//    }
//}

//struct TestWrappedHStackView_Previews: PreviewProvider {
//    static var previews: some View {
//        TestWrappedHStackView()
//    }
//}

struct TagsView: View {
    
    let items: [String]
    var groupedItems: [[String]] = [[String]]()
    let screenWidth = UIScreen.main.bounds.width
    @Binding var selected: [String]
    init(items: [String], selected: Binding<[String]>) {
        self.items = items
        self._selected = selected
        self.groupedItems = createGroupedItems(items)
    }
    
    private func createGroupedItems(_ items: [String]) -> [[String]] {
        
        var groupedItems: [[String]] = [[String]]()
        var tempItems: [String] =  [String]()
        var width: CGFloat = 0
        
        for word in items {
            
            let label = UILabel()
            label.text = word
            label.font = UIFont(name: "CircularStd-Bold", size: screenSize.width * 0.04)
            
            let labelWidth = screenSize.width * 0.04 * CGFloat(word.count)
            
            if (width + labelWidth ) < screenSize.width {
                width += labelWidth
                tempItems.append(word)
            } else {
                width = labelWidth
                groupedItems.append(tempItems)
                tempItems.removeAll()
                tempItems.append(word)
            }
            
        }
        
        groupedItems.append(tempItems)
        return groupedItems
        
    }
    
    var body: some View {
        ScrollView {
        VStack(alignment: .leading) {
            
            ForEach(groupedItems, id: \.self) { subItems in
                HStack {
                    ForEach(subItems, id: \.self) { interest in
                        
                        
                        Button(action: {
                            if selected.contains(where: {$0 == interest}) {
                                selected.removeAll(where: {$0 == interest})
                            } else {
                                selected.append(interest)
                            }
                        }, label: {
                            
                            MyText(text: interest, size: screenSize.width * 0.04, bold: true, alignment: .center, color: .white)
//                                    .fixedSize(horizontal: true, vertical: false)
                                .fixedSize()
                                .frame(height: screenSize.height * 0.04)
//                                .scaledToFill()
                                .padding(.horizontal, 20)
                                .lineLimit(1)
                                .background(Capsule().foregroundColor(selected.contains(where: {$0 == interest}) ? .accentColor : Color("AccentGray")))
//                                .truncationMode(.none)
                        })
                        
                    }
                }
                .padding(.bottom, 5)
            }
            
            Spacer()
        }
    }
    }
    
}
