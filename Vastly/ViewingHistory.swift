//
//  ViewingHistory.swift
//  Vastly
//
//  Created by Casey Traina on 9/12/23.
//

import SwiftUI

struct ViewingHistory: View {
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var viewModel: CatalogViewModel
    
    var body: some View {
        VideoListView(title: "Viewing History",
                      icon: "clock.arrow.circlepath",
                      videoList: $viewModel.viewed_videos,
                      loading: $viewModel.viewedVideosProcessing,
                      loadFunc: viewModel.fetchViewedVideos)
        .environmentObject(viewModel)
        .environmentObject(authModel)
    }
}
