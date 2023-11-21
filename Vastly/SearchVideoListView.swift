//
//  SearchVideoListView.swift
//  Vastly
//
//  Created by Michael Murray on 8/21/23
//
import SwiftUI

struct SearchVideoListView: View {
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var viewModel: CatalogViewModel

    var title: String
    let color = Color(red: 18.0 / 255, green: 18.0 / 255, blue: 18.0 / 255)

    @State var author = EXAMPLE_AUTHOR
    @State var current = 0
    @State var isPlaying = true
    @State var publisherIsTapped = false
    @State var dummyPubTapped = false // dummy variable

    @State var isLinkActive = false

    @Binding var videos: [Video]
    @Binding var oldPlaying: Bool
    @State var text = ""

//    init(title: String, videos: Binding<[Video]>, oldPlaying: Binding<Bool>) {
//        self._oldPlaying = oldPlaying
//        self.videos = videos
//        let appearance = UINavigationBarAppearance()
//        appearance.configureWithOpaqueBackground()
//        appearance.backgroundColor = .black
//        UINavigationBar.appearance().standardAppearance = appearance
//        UINavigationBar.appearance().scrollEdgeAppearance = appearance
//    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                VStack {
                    HStack {
                        MyText(text: title, size: geo.size.width * 0.06, bold: true, alignment: .leading, color: .white)
                            .padding()
                        Spacer()
                    }
                    if videos.isEmpty {
                        MyText(text: "No results.", size: geo.size.width * 0.04, bold: true, alignment: .center, color: .white)
                            .padding()
                    } else {
                        ScrollView(showsIndicators: false) {
                            ForEach(videos) { video in
                                NavigationLink(destination: SearchVideoView(query: text, vids: $videos, current_playing: $current, isPlaying: $isPlaying, publisherIsTapped: $dummyPubTapped)
                                    .environmentObject(authModel)
                                    .environmentObject(viewModel)
                                    .background(Color("BackgroundColor")),
                                    isActive: $isLinkActive)
                                {
                                    EmptyView()
                                }

                                Button(action: {
                                    current = videos.firstIndex(where: { $0.id == video.id }) ?? 0
                                    oldPlaying = false
                                    isLinkActive = true
                                }, label: {
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
                            }
                        }
                    }
                    Spacer()
                }
                if publisherIsTapped {
                    AuthorProfileView(author: author, publisherIsTapped: $publisherIsTapped)
                }
            }
        }
    }
}
