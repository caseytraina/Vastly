//
//  CatalogTest.swift
//  VastlyTests
//
//  Created by Michael Murray on 11/10/23.
//

import XCTest

@testable import Vastly

final class CatalogTest: XCTestCase {
    let catalog = Catalog()
    let channels = [
        Channel(id: "id1", order: 1, title: "My First Channel", color: .white, isActive: true),
        Channel(id: "id1", order: 1, title: "My Second Channel", color: .white, isActive: true)
    ]
    override func setUpWithError() throws {
        let videoOne = FirebaseData(title: "My First Video", author: nil, bio: nil, location: nil, date: nil, channels: [], youtubeURL: nil)
        let videoTwo = FirebaseData(title: "My Second Video", author: nil, bio: nil, location: nil, date: nil, channels: [], youtubeURL: nil)
        let videoThree = FirebaseData(title: "My Third Video", author: nil, bio: nil, location: nil, date: nil, channels: [], youtubeURL: nil)
        
        let channelOneVideos = ChannelVideos(channel: channels[0], user: nil, authors: [])
        channelOneVideos.addVideo(id: "video1", unfilteredVideo: videoOne)
        
        let channelTwoVideos = ChannelVideos(channel: channels[1], user: nil, authors: [])
        channelTwoVideos.addVideo(id: "video2", unfilteredVideo: videoTwo)
        channelTwoVideos.addVideo(id: "video3", unfilteredVideo: videoThree)
        
        catalog.addChannel(channelOneVideos)
        catalog.addChannel(channelTwoVideos)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testChannelSwitching() throws {
        catalog.changeToChannel(channels[0])
        
        if let nextChannel = catalog.nextChannel() {
            XCTAssert(nextChannel.channel.title == "My Second Channel")
        }
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
