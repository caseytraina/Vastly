//
//  SearchBar.swift
//  Vastly
//
//  Created by Casey Traina on 9/14/23.
//

import SwiftUI
import AlgoliaSearchClient

struct NewSearchBar: View {
    
//    @EnvironmentObject var viewModel: VideoViewModel
    
//    @StateObject var controller: NewAlgoliaController
//
    let color = Color(red: 18.0/255, green: 18.0/255, blue: 18.0/255)

//    @State var text = ""
//
    var viewModel: VideoViewModel
    @StateObject var controller: NewAlgoliaController
    @State var text = ""

    init(viewModel: VideoViewModel) {
        self.viewModel = viewModel
        _controller = StateObject(wrappedValue: NewAlgoliaController(viewModel: viewModel))
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                VStack {
                    TextField("Search...",text: $text)
                        .textFieldStyle(GradientTextFieldBackground(systemImageString: "magnifyingglass"))
                        .frame(width: geo.size.width * 0.9)
                    //                    List(controller.videos) { video in
                    if !controller.videos.isEmpty {
                        HStack {
                            MyText(text: "Clips", size: geo.size.width * 0.06, bold: true, alignment: .leading, color: .white)
                                .padding()
                            Spacer()
                        }
                        ScrollView(showsIndicators: false) {
                            ForEach(controller.videos) { video in
                                HStack(alignment: .center) {
                                    
                                    AsyncImage(url: viewModel.getThumbnail(video: video), content: { image in
                                        image
                                            .resizable()
                                            .frame(maxWidth: geo.size.width * 0.2, maxHeight: geo.size.width * 0.2)
                                            .padding(.horizontal)
                                            .scaledToFit()
                                    }, placeholder: {
                                        AsyncImage(url: video.author.fileName, content: { image in
                                            image
                                                .resizable()
                                                .frame(maxWidth: geo.size.width * 0.15, maxHeight: geo.size.width * 0.15)
                                                .padding(.horizontal)
                                        }, placeholder: {
                                            Color("BackgroundColor")
                                                .frame(width: geo.size.width * 0.15, height: geo.size.width * 0.15)
                                                .padding(.horizontal)
                                        })
                                    })

                                    VStack(alignment: .leading) {
                                        MyText(text: video.title, size: geo.size.width * 0.04, bold: true, alignment: .leading, color: .white)
                                            .lineLimit(2)
                                        MyText(text: video.author.name ?? "", size: geo.size.width * 0.03, bold: false, alignment: .leading, color: .white)
                                            .lineLimit(1)
                                        
                                    }
                                    Spacer()
                                }
                                .frame(height: geo.size.width * 0.15)
                                .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(color)
                                )
                            } // end foreach
                        } // end scrollview
                        .frame(maxHeight: geo.size.height * 0.4)
                    }
                    
                    if !controller.videos.isEmpty {
                        HStack {
                            MyText(text: "Podcasts", size: geo.size.width * 0.06, bold: true, alignment: .leading, color: .white)
                                .padding()
                            Spacer()
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(controller.authors) { author in
                                    VStack(alignment: .center) {
                                        AsyncImage(url: author.fileName, content: { image in
                                            image
                                                .resizable()
                                                .frame(maxWidth: geo.size.width * 0.25, maxHeight: geo.size.width * 0.25)
                                                .padding(.horizontal)
                                        }, placeholder: {
                                            Color("BackgroundColor")
                                                .frame(width: geo.size.width * 0.15, height: geo.size.width * 0.15)
                                                .padding(.horizontal)
                                        })
                                        //                                VStack(alignment: .leading) {
                                        MyText(text: author.name ?? "", size: geo.size.width * 0.04, bold: true, alignment: .leading, color: .white)
                                            .frame(maxWidth: geo.size.width * 0.4)
                                            .lineLimit(2)
                                        
                                        //                                }
                                    }
                                    .frame(width: geo.size.width * 0.35, height: geo.size.height * 0.3)
                                    .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .foregroundColor(color)
                                    )
                                }
                            } // end foreach
                        } // end scrollview
                        .frame(maxHeight: geo.size.height * 0.3)
                        
                    }
                    Spacer()
                    
                    
                    //                    }
                    //                    .colorInvert()
                }
            }
            
        }
        .onChange(of: text) { newText in
            controller.search(for: newText)
        }
    }
    
    
}


class NewAlgoliaController: ObservableObject {
    
    let client: SearchClient
    let index: Index
    
    let viewModel: VideoViewModel
    
//    @Published var text: String = "" {
//        didSet {
//            self.search(for: text)
//        }
//    }
    
    @Published var videos: [Video] = []
    @Published var authors: [Author] = []

    
    init(viewModel: VideoViewModel) {
        
        self.client = SearchClient(appID: "JDJU8ZVIM4", apiKey: "6eb916eda40c8a7b7f2c116b80e72a27")
        self.index = client.index(withName: "ios_app_videos")
        self.viewModel = viewModel
    }
    
    
    func search(for query: String) {

        var query = Query(query)
        query.hitsPerPage = 40
        
        index.search(query: query) { result in

            if case .success(let response) = result {
                
                DispatchQueue.main.async {
                    self.videos = []
                    self.authors = []
                }
                
                print("Response hits: \(response.hits)")

                let decoder = JSONDecoder()
                for hit in response.hits {
                    do {
                        let data = hit.object.debugDescription.data(using: .utf8)
                        let decoded = try decoder.decode(Hit.self, from: data!)
                        
                        if let path = decoded.path {
                            print("path: \(path)")
                            if path.contains("videos") {
                                
                                let video = Video(
                                    id: hit.objectID.rawValue,
                                    title: decoded.title ?? "",
                                    author: self.viewModel.authors.first(where: { $0.name == decoded.author}) ?? EXAMPLE_AUTHOR,
                                    bio: decoded.bio ?? "",
                                    date: decoded.date,
                                    channels: decoded.channels ?? [],
                                    url: self.viewModel.getVideoURL(from: decoded.url ?? "") ?? EMPTY_VIDEO.url,
                                    youtubeURL: decoded.youtubeURL ?? "")
                                
                                
                                
                                print("Data Title: \(video.title)")
                                DispatchQueue.main.async {
                                    self.videos.append(video)
                                }
                                
                            } else if path.contains("authors") {
                                
//                                let author = Author(
//                                    id: UUID(),
//                                    text_id: hit.objectID.rawValue,
//                                    name: decoded.name,
//                                    bio: decoded.bio,
//                                    fileName: EXAMPLE_AUTHOR.fileName,
//                                    website: decoded.website,
//                                    apple: decoded.apple,
//                                    spotify: decoded.spotify)
                                
                                let author = self.viewModel.authors.first(where:  { $0.name == decoded.name})
                                if let author {
                                    DispatchQueue.main.async {
                                        self.authors.append(author)
                                    }
                                }
                            }
                        }
                    } catch {
                        print("Error parsing hits: \(error)")
                    }
                    
                }
                  print("Response: \(response)")
            } else if case .failure (let error) = result {
                  print("Error searching: \(error)")
            }
        }
        
    }

}
    


//struct SearchBar_Previews: PreviewProvider {
//    static var previews: some View {
//        NewSearchBar(controller: NewAlgoliaController())
//    }
//}






struct Hit: Codable {
    let path: String?

    let title: String?
    let bio: String?
    let url: String?
    let channels: [String]?
    let date: String?
    let author: String?
    let youtubeURL: String?

    let name: String?
    let spotify: String?
    let apple: String?
    let website: String?
    
    enum CodingKeys: String, CodingKey {
        case path
        case title
        case bio
        case url = "fileName"
        case channels
        case author
        case youtubeURL
        case date

        case name
        case spotify
        case website
        case apple
    }
    
}
