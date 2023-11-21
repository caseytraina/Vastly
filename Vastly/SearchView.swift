//
//  SearchBar.swift
//  Vastly
//
//  Created by Casey Traina on 9/14/23.
//

import AlgoliaSearchClient
import SwiftUI

struct SearchView: View {
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var viewModel: CatalogViewModel

    var authors: [Author]

//    @StateObject var controller: NewAlgoliaController
//
    let color = Color(red: 18.0 / 255, green: 18.0 / 255, blue: 18.0 / 255)

//    @State var text = ""

    @State var author = EXAMPLE_AUTHOR

    @State var current = 0
    @State var isPlaying = true
    @State var publisherIsTapped = false
    @State var dummyPubTapped = false // dummy variable

    @State var isLinkActive = false
    @FocusState private var textFocused: Bool

    @StateObject var controller: NewAlgoliaController
    @State var text = ""

    @Binding var playing: Bool

    @FocusState private var searchIsFocused: Bool

    init(authors: [Author], playing: Binding<Bool>) {
        self.authors = authors
        _controller = StateObject(wrappedValue: NewAlgoliaController(all_authors: authors))
        self._playing = playing

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
                    TextField("Search your favorite topics, shows, interests...", text: $text)
                        .textFieldStyle(GradientTextFieldBackground(systemImageString: "magnifyingglass"))
//                        .focused($textFocused)
                        .frame(width: geo.size.width * 0.9)
                        .padding(.top)
                        .focused($searchIsFocused)
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
                        VideoListView(title: "Clips",
                                            videos: $controller.videos,
                                            playing: $playing)
                            .scrollDismissesKeyboard(.immediately)
                    }
                    Spacer()
                }

                if publisherIsTapped {
                    AuthorProfileView(author: author, publisherIsTapped: $publisherIsTapped)
                }
            } // end ZStack
            .onTapGesture {
                if searchIsFocused {
                    searchIsFocused.toggle()
                    Task {
                        await authModel.addToSearch(text)
                    }
                }
            }
        } // end geo reader

        .onChange(of: text) { newText in
            controller.search(for: newText)
        }
    }
}

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
            if case let .success(response) = result {
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
                                    author: self.all_authors.first(where: { $0.text_id == decoded.author }) ?? EXAMPLE_AUTHOR,
                                    bio: decoded.bio ?? "",
                                    date: decoded.date,
                                    channels: decoded.channels ?? [],
                                    url: self.getVideoURL(from: decoded.url ?? "") ?? EMPTY_VIDEO.url,
                                    youtubeURL: decoded.youtubeURL ?? ""
                                )

                                print("Data Title: \(video.title)")
                                DispatchQueue.main.async {
                                    self.videos.append(video)
                                }

                            } else if path.contains("authors") {
                                let author = self.all_authors.first(where: { $0.text_id == hit.objectID.rawValue })
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
            } else if case let .failure(error) = result {
                print("Error searching: \(error)")
            }
        }
    }
}

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
