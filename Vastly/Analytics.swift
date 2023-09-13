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
import FirebaseFirestore
import FirebaseFirestoreSwift

import Amplitude

import CoreMedia

func videoWatched(for video: Video, with user: User?, profile: Profile?) {
    
    let db = Firestore.firestore()
    let userRef = {
        if (profile?.phoneNumber != nil) {
            return db.collection("users").document((profile?.phoneNumber)!);
        } else if (profile?.email != nil) {
            return db.collection("users").document((profile?.email)!);
        }
        return db.collection("users").document("");
    }
    
    // Update Firebase viewed videos

    
    
    Amplitude.instance().logEvent(
        "Video Watched",
        withEventProperties: [
            "Video ID": video.id as NSObject,
            "Video Title": video.title as NSObject,
            "Video Channels": video.channels as NSObject,
            "Author": video.author.name ?? "" as NSObject,
            "Name": "\(profile?.firstName) \(profile?.lastName)"
        ])

    
    
    print("Video Selection Logged")
}

func channelTapped(for channel: Channel, with user: User?) {
    
    Amplitude.instance().logEvent(
        "Channel Tapped",
        withEventProperties: [
            "Channel": channel.id as NSObject
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

func logWatchTime(from start: Date, to end: Date, for video: Video, time: Double, watched: Double?, with user: User?, profile: Profile?) {
    
    let db = Firestore.firestore()
    let userRef = {
        if (profile?.phoneNumber != nil) {
            return db.collection("users").document((profile?.phoneNumber)!);
        } else if (profile?.email != nil) {
            return db.collection("users").document((profile?.email)!);
        }
        return db.collection("users").document("");
    }
    
//    let watchTime = end.timeIntervalSince(start)
    let watchTime = min(watched ?? 10000.0, end.timeIntervalSince(start).magnitude)
    let realTime = watchTime >= time ? time : watchTime
    let percentage = ceil((realTime/time) * 100)
    
    if realTime > 3 {
        userRef().updateData([
            "viewed_videos": FieldValue.arrayUnion([video.id])
        ])
    }
    
    
    Amplitude.instance().logEvent(
        "Video Watch Time",
        withEventProperties: [
            "Video ID"      : video.id as NSObject,
            "Video Title"   : video.title as NSObject,
            "Author"    : video.author.name ?? "" as NSObject,
            "Video Channels" : video.channels as NSObject,
            "Watch Time"    : watchTime as NSNumber,
            "User ID": user?.uid,
            "Name": "\(profile?.firstName) \(profile?.lastName)"
        ])
    
    Amplitude.instance().logEvent(
        "Video Percentage Watched",
        withEventProperties: [
            "Video ID"      : video.id as NSObject,
            "Video Title"   : video.title as NSObject,
            "Author"    : video.author.name ?? "" as NSObject,
            "Video Channels" : video.channels as NSObject,
            "percentage_watched"    : percentage as NSNumber,
            "User ID": user?.uid,
            "Name": "\(profile?.firstName) \(profile?.lastName)"

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

func videoCompleted(for video: Video, with user: User?, profile: Profile?) {
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
            "Video ID"      : video.id as NSObject,
            "Video Title"   : video.title as NSObject,
            "Author"    : video.author.name ?? "" as NSObject,
            "Video Channels" : video.channels as NSObject,
            "User ID": user?.uid,
            "Name": "\(profile?.firstName) \(profile?.lastName)"
        ])
    
}
