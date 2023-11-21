//
//  LikesListView.swift
//  Vastly
//
//  Created by Casey Traina on 7/31/23.
//

import SwiftUI

struct LikesListView: View {
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var viewModel: CatalogViewModel
    
    @Binding var playing: Bool
    
    var body: some View {
        VideoListView(title: "Bookmarks",
                            videos: $authModel.likedVideos,
                            playing: $playing)
        .environmentObject(viewModel)
        .environmentObject(authModel)
        .onAppear {
            Task {
                await authModel.fetchLikedVideos(authors: viewModel.authors)
            }
        }
    }
}
