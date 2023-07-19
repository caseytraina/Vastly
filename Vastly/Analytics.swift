//
//  Analytics.swift
//  Vastly
//
//  Created by Casey Traina on 6/26/23.
//

import Foundation
import Firebase
import FirebaseCore
import FirebaseAuth
import FirebaseAnalytics

import Amplitude

import CoreMedia

func videoWatched(for video: Video, with user: User?) {
//    Analytics.logEvent(AnalyticsEventSelectItem, parameters: [
//        AnalyticsParameterItemID: video.id.uuidString as NSObject,
//        AnalyticsParameterItemName: video.title as NSObject,
//        AnalyticsParameterItemCategory: video.channels[0] as NSObject,
//        AnalyticsParameterAffiliation: video.author.name ?? "" as NSObject,
//        "list_id": video.channels[0] as NSObject,
//        "list_name": video.channels[0].capitalized as NSObject,
//        "user_id": user?.uid
//    ])
    
    
    Amplitude.instance().logEvent(
        "Video Watched",
        withEventProperties: [
            "Video ID": video.id.uuidString as NSObject,
            "Video Title": video.title as NSObject,
            "Video Channels": video.channels as NSObject,
            "Author": video.author.name ?? "" as NSObject
        ])

    
    
    print("Video Selection Logged")
}

func channelTapped(for channel: Channel, with user: User?) {
    
    Amplitude.instance().logEvent(
        "Channel Tapped",
        withEventProperties: [
            "Channel": channel.rawValue.capitalized as NSObject
        ])
    
    print("Video Selection Logged")
}

func logLogin() {
//    Analytics.logEvent(AnalyticsEventLogin, parameters: nil)
    Amplitude.instance().logEvent("Log In")
}

func logSignUp(method: String) {
    Amplitude.instance().logEvent("Sign Up")
}

func logScreenSwitch(to screen: String) {
//    Analytics.logEvent(AnalyticsEventScreenView, parameters: [
//        AnalyticsParameterScreenName: screen as NSObject
//    ])

    Amplitude.instance().logEvent(
        "Screen Switch",
        withEventProperties: [
            "To": screen as NSObject
        ])
    
}

func logWatchTime(from start: Date, to end: Date, for video: Video, time: Double, watched: Double?, with user: User?) {
//    let watchTime = end.timeIntervalSince(start)
    let watchTime = min(watched ?? 10000.0, end.timeIntervalSince(start).magnitude)
    
    let realTime = watchTime >= time ? time : watchTime
    
    let percentage = ceil((realTime/time) * 100)
    
    Amplitude.instance().logEvent(
        "Video Watch Time",
        withEventProperties: [
            "Video ID"      : video.id.uuidString as NSObject,
            "Video Title"   : video.title as NSObject,
            "Author"    : video.author.name ?? "" as NSObject,
            "Video Channels" : video.channels as NSObject,
            "Watch Time"    : watchTime as NSNumber,
            "User ID": user?.uid
        ])
    
    Amplitude.instance().logEvent(
        "Video Percentage Watched",
        withEventProperties: [
            "Video ID"      : video.id.uuidString as NSObject,
            "Video Title"   : video.title as NSObject,
            "Author"    : video.author.name ?? "" as NSObject,
            "Video Channels" : video.channels as NSObject,
            "percentage_watched"    : percentage as NSNumber,
            "User ID": user?.uid
        ])
    
//    Analytics.logEvent("video_percentage_watched", parameters: [
//        "video_id"      : video.id.uuidString as NSObject,
//        "video_title"   : video.title as NSObject,
//        "video_author"    : video.author.name ?? "" as NSObject,
//        "video_channel" : video.channels[0].capitalized as NSObject,
//        "percentage_watched"    : percentage as NSNumber,
//        "user_id": user?.uid
//    ])
}

func videoCompleted(for video: Video, with user: User?) {
//    Analytics.logEvent("watched_to_completion", parameters: [
//        "video_id"      : video.id.uuidString as NSObject,
//        "video_title"   : video.title as NSObject,
//        "video_author"    : video.author.name ?? "" as NSObject,
//        "video_channel" : video.channels[0].capitalized as NSObject,
//        "user_id": user?.uid
//    ])
    
    Amplitude.instance().logEvent(
        "Video Completed",
        withEventProperties: [
            "Video ID"      : video.id.uuidString as NSObject,
            "Video Title"   : video.title as NSObject,
            "Author"    : video.author.name ?? "" as NSObject,
            "Video Channels" : video.channels as NSObject,
            "User ID": user?.uid
        ])
    
}
