//
//  VideoListView.swift
//  Vastly
//
//  Created by Michael Murray on 8/21/23
//
import SwiftUI

struct VideoListView: View {
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var viewModel: CatalogViewModel

    var title: String
    let color = Color(red: 5 / 255, green: 5 / 255, blue: 5 / 255)

    @State var author = EXAMPLE_AUTHOR
    @State var current = 0
    @State var isPlaying = true
    @State var publisherIsTapped = false
    @State var dummyPubTapped = false // dummy variable

    @State var isLinkActive = false

    @Binding var videos: [Video]
    @Binding var playing: Bool
    @State var text = ""

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
                                NavigationLink(destination:
                                    SingleVideoView(video: videos[current])
                                       .environmentObject(authModel)
                                       .environmentObject(viewModel)
                                    
                                , isActive: $isLinkActive) {
                                    EmptyView()
                                }

                                Button(action: {
                                    current = videos.firstIndex(where: { $0.id == video.id }) ?? 0
                                    playing = false
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
                                    .frame(width: geo.size.width*0.9, height: geo.size.width * 0.25)
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
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .black
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
