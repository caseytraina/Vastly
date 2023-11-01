//
//  SearchBar.swift
//  Vastly
//
//  Created by Casey Traina on 9/14/23.
//

import SwiftUI
import AlgoliaSearchClient

struct NewSearchBar: View {
    
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var viewModel: VideoViewModel

    var all_authors: [Author]
    
//    @StateObject var controller: NewAlgoliaController
//
    let color = Color(red: 18.0/255, green: 18.0/255, blue: 18.0/255)

//    @State var text = ""
    
    @State var author = EXAMPLE_AUTHOR
    
    @State var current = 0
    @State var isPlaying = true
    @State var publisherIsTapped = false
    @State var dummyPubTapped = false // dummy variable

    @State var isLinkActive = false
    @FocusState private var textFocused: Bool
    
//    var viewModel: VideoViewModel
    
    @StateObject var controller: NewAlgoliaController
    @State var text = ""
    
    @Binding var oldPlaying: Bool

    @FocusState private var searchIsFocused: Bool

    init(all_authors: [Author], oldPlaying: Binding<Bool>) {
        self.all_authors = all_authors
        _controller = StateObject(wrappedValue: NewAlgoliaController(all_authors: all_authors))
        self._oldPlaying = oldPlaying
//        _controller.wrappedValue.viewModel = viewModel
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                VStack {
                    TextField("Search your favorite topics, shows, interests...",text: $text)
                        .textFieldStyle(GradientTextFieldBackground(systemImageString: "magnifyingglass"))
//                        .focused($textFocused)
                        .frame(width: geo.size.width * 0.9)
                        .padding(.top)
                        .focused($searchIsFocused)
//                        .onSubmit {
//                            Task {
//                                await authModel.addToSearch(text)
//                            }
//                        }
                    //                    List(controller.videos) { video in
                    if text.isEmpty {
                        VStack {

                            if let queries = authModel.searchQueries {
                                
                                HStack {
                                    MyText(text: "Recent Searches", size: 18, bold: true, alignment: .center, color: .white)
                                        .padding()
                                    Spacer()
                                }
                                
                                ForEach(queries, id: \.self) { query in
                                    HStack {
                                        Button(action: {
                                            text = query
                                        }, label: {
                                            Image(systemName: "clock.arrow.circlepath")
                                                .font(.system(size: 18))
                                                .foregroundStyle(.gray)
                                                .padding(5)
                                            MyText(text: query, size: 18, bold: false, alignment: .leading, color: .gray)
                                                .lineLimit(1)
                                            Spacer()
                                        })
                                        Spacer()
                                        Button(action: {
                                            Task {
                                                await authModel.removeFromSearch(query)
                                            }
                                        }, label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 18))
                                                .foregroundStyle(.gray)
                                                .padding(5)

                                        })
                                    }
                                    
                                }
                            }
                        }
                        
                        
                    } else {
                        HStack {
                            MyText(text: "Clips", size: geo.size.width * 0.06, bold: true, alignment: .leading, color: .white)
                                .padding()
                            Spacer()
                        }
                        if controller.videos.isEmpty {
                            MyText(text: "No results.", size: geo.size.width * 0.04, bold: true, alignment: .center, color: .white)
                                .padding()
                        } else {
                            
                            ScrollView(showsIndicators: false) {
                                ForEach(controller.videos) { video in
                                    NavigationLink(destination: SearchVideoView(query: text, vids: $controller.videos, current_playing: $current, isPlaying: $isPlaying, publisherIsTapped: $dummyPubTapped)
                                        .environmentObject(authModel)
                                        .environmentObject(viewModel)
                                        .background(Color("BackgroundColor")),
                                                   isActive: $isLinkActive) {
                                        EmptyView()
                                    }
                                                                        
                                    Button(action: {
                                        current = controller.videos.firstIndex(where:  { $0.id == video.id}) ?? 0
                                        oldPlaying = false
                                        isLinkActive = true
                                        
//                                        Task {
//                                            await authModel.addToSearch(text)
//                                        }

                                        
                                    }, label: {
                                        
                                        //                                   })
                                        HStack(alignment: .center) {
                                            
                                            AsyncImage(url: viewModel.getThumbnail(video: video), content: { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
                                                    .frame(height: geo.size.width * 0.15)
                                                    .scaledToFit()
                                                    .padding(.horizontal)
                                            }, placeholder: {
                                                Color("BackgroundColor")
                                                    .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
                                                    .frame(height: geo.size.width * 0.15)
                                                    .scaledToFit()
                                                    .padding(.horizontal)
                                            })
                                            
                                            VStack(alignment: .leading) {
                                                MyText(text: video.title, size: geo.size.width * 0.04, bold: true, alignment: .leading, color: .white)
                                                    .lineLimit(2)
                                                MyText(text: video.author.name ?? "", size: geo.size.width * 0.03, bold: false, alignment: .leading, color: .white)
                                                    .lineLimit(1)
                                                
                                            }
                                            Spacer()
                                        }
                                        .frame(width: geo.size.width, height: geo.size.width * 0.25)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .foregroundColor(color)
                                        )
                                        
                                    })
                                    .padding(.top)
                                    
                                } // end foreach
                            } // end scrollview
                            .scrollDismissesKeyboard(.immediately)


//                            .frame(maxHeight: geo.size.height * 0.4)
                        }
                        
                    }

                    Spacer()
                }

                if publisherIsTapped {
                    AuthorProfileView(author: author, publisherIsTapped: $publisherIsTapped)
                }
                
            } //end ZStack
            .onTapGesture {
                if searchIsFocused {
                    searchIsFocused.toggle()
                    Task {
                        await authModel.addToSearch(text)
                    }
                }
            }
//            .onTapGesture {
//                textFocused = false
//            }
            
            
        } //end geo reader

        .onChange(of: text) { newText in
            controller.search(for: newText)
        }
        .onAppear {
//            oldPlaying = false
        }
    } // end body
    
    
}// end class


class NewAlgoliaController: ObservableObject {
    
    let client: SearchClient
    let index: Index
    
    var all_authors: [Author]
    
    @Published var videos: [Video] = []
    @Published var authors: [Author] = []

    
    init(all_authors: [Author]) {
        self.client = SearchClient(appID: "JDJU8ZVIM4", apiKey: "6eb916eda40c8a7b7f2c116b80e72a27")
        self.index = client.index(withName: "ios_app_videos")
        self.all_authors = all_authors
    }
    
    // This function turns a path to a URL of a cached and compressed video, connecting to our CDN imagekit which is a URL-based video and image delivery and transformation company.
    func getVideoURL(from location: String) -> URL? {

        var allowedCharacters = CharacterSet.urlQueryAllowed
        allowedCharacters.insert("/")
        
        var fixedPath = location.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
        fixedPath = fixedPath.replacingOccurrences(of: "’", with: "%E2%80%99")
        
        let urlStringUnkept: String = IMAGEKIT_ENDPOINT + fixedPath + "?tr=f-auto"
        var urlString = urlStringUnkept

        print(urlString)
        if let url = URL(string: urlString ?? "") {
            return url
        } else {
            return EMPTY_VIDEO.url
            print("URL is invalid")
        }
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
                                    author: self.all_authors.first(where: {$0.text_id == decoded.author}) ?? EXAMPLE_AUTHOR,
                                    bio: decoded.bio ?? "",
                                    date: decoded.date,
                                    channels: decoded.channels ?? [],
                                    url: self.getVideoURL(from: decoded.url ?? "") ?? EMPTY_VIDEO.url,
                                    youtubeURL: decoded.youtubeURL ?? "")
                                
                                print("Data Title: \(video.title)")
                                DispatchQueue.main.async {
                                    self.videos.append(video)
                                }
                                
                            } else if path.contains("authors") {

                                let author = self.all_authors.first(where:  { $0.text_id == hit.objectID.rawValue})
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
