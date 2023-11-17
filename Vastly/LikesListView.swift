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
    
    var body: some View {
        VideoListView(title: "Bookmarks", 
                      icon: "book.pages",
                      videoList: $authModel.liked_videos,
                      loading: $viewModel.likedVideosProcessing,
                      loadFunc: viewModel.fetchLikedVideos)
        .environmentObject(viewModel)
        .environmentObject(authModel)
    }
}
