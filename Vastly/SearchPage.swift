//
//  SearchPage.swift
//  Vastly
//
//  Created by Casey Traina on 9/13/23.
//

import SwiftUI
import AlgoliaSearchClient
import InstantSearch
import InstantSearchCore
import InstantSearchSwiftUI

struct SearchPage: View {
    
    @ObservedObject var searchBoxController: SearchBoxObservableController
    @ObservedObject var hitsController: HitsObservableController<FirebaseData>

    @State private var isEditing = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                VStack(spacing: 7) {
                    SearchBar(text: $searchBoxController.query,
                              isEditing: $isEditing, placeholder: " Search ...", onSubmit: searchBoxController.submit)
//                    .colorScheme(.dark)
                    .colorInvert()
                    .frame(height: geo.size.height * 0.1)
                    .font(Font.custom("CircularStd-Bold", size: geo.size.width * 0.05))
//                    .padding()
                    .foregroundColor(.red)
                    HitsList(hitsController) { (hit, _) in
                        VStack(alignment: .leading, spacing: 5) {
                            MyText(text: hit?.title ?? "", size: geo.size.width * 0.05, bold: true, alignment: .leading, color: .white)
                                .padding(.horizontal)
                            MyText(text: hit?.author ?? "", size: geo.size.width * 0.04, bold: false, alignment: .leading, color: .white)
                                .padding(.horizontal)

                            Divider()
                        }
                    } noResults: {
                        Text("No Results")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
    }


    
}

struct SearchPage_Previews: PreviewProvider {
    
    static let algoliaController = AlgoliaController()
    
    static var previews: some View {
      NavigationView {
        SearchPage(searchBoxController: algoliaController.searchBoxController,
                    hitsController: algoliaController.hitsController)
      }.onAppear {
        algoliaController.searcher.search()
      }
    }
}

class AlgoliaController {
  
  let searcher: HitsSearcher

  let searchBoxInteractor: SearchBoxInteractor
  let searchBoxController: SearchBoxObservableController

  let hitsInteractor: HitsInteractor<FirebaseData>
  let hitsController: HitsObservableController<FirebaseData>
  
  init() {
    self.searcher = HitsSearcher(appID: "JDJU8ZVIM4",
                                 apiKey: "6eb916eda40c8a7b7f2c116b80e72a27",
                                 indexName: "ios_app_videos")
    self.searchBoxInteractor = .init()
    self.searchBoxController = .init()
    self.hitsInteractor = .init()
    self.hitsController = .init()
    setupConnections()
  }
  
  func setupConnections() {
    searchBoxInteractor.connectSearcher(searcher)
    searchBoxInteractor.connectController(searchBoxController)
    hitsInteractor.connectSearcher(searcher)
    hitsInteractor.connectController(hitsController)
  }

}
