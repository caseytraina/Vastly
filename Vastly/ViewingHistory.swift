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
    
    @Binding var playing: Bool
    
    var body: some View {
        SearchVideoListView(title: "Viewing History", 
                            videos: $authModel.viewedVideos,
                            playing: $playing)
        .environmentObject(viewModel)
        .environmentObject(authModel)
        .onAppear {
            Task {
                await authModel.fetchViewedVideos(authors: viewModel.authors)
            }
        }

    }
}
