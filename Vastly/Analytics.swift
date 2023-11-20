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

private func commonProperties(video: Video) -> [String: NSObject] {
    return [
        "Video ID": video.id as NSObject,
        "Video Title": video.title as NSObject,
        "Video Channels": video.channels as NSObject,
        "Author": (video.author.name ?? "") as NSObject
    ]
}

private func commonProperties(user: User?, profile: Profile?) -> [String: NSObject] {
    return [
        "User ID": (user?.uid ?? "") as NSObject,
        "Name": (profile?.name() ?? "") as NSObject
    ]
}

private func commonProperties(video: Video, user: User?, profile: Profile?) -> [String: NSObject] {
    let videoProperties = commonProperties(video: video)
    let userProperties = commonProperties(user: user, profile: profile)
    
    var common: [String: NSObject] = [:]
    for (prop, val) in videoProperties {
        common[prop] = val
    }
    for (prop, val) in userProperties {
        common[prop] = val
    }
    
    return common
}

func videoClicked(for video: Video, with user: User?, profile: Profile?, watchedIn: Channel) {
    var properties = commonProperties(video: video, user: user, profile: profile)
    properties["Watched In Channel"] = watchedIn.id as NSObject
    Amplitude.instance().logEvent(
        "Video Clicked",
        withEventProperties: properties
    )
}

func videoWatched(from start: Date, to end: Date, for video: Video, time: Double,
                  watched: Double?, with user: User?, profile: Profile?, viewModel: CatalogViewModel, watchedIn: Channel) {
    let watchTime = watched ?? end.timeIntervalSince(start).magnitude
    let realTime = watchTime >= time ? time : watchTime
    let percentage = ceil((realTime/time) * 100)
    
    // TODO: This should be moved somewhere else, doesn't belong in analytics
    let db = Firestore.firestore()
    let userRef = db.collection("users").document(profile?.phoneNumber ?? profile?.email ?? "")
    let videoRef = db.collection("videos").document(video.id)
    let userViewedRef = userRef.collection("viewedVideos").document(video.id)
    
    if realTime > 3 { // CHECK ID OR TITLE
        userViewedRef.setData([
            "createdAt": Timestamp(date: Date()),
            "watchTime": watchTime,
            "watchPercentage": percentage,
            "inChannel": watchedIn.id
        ])
        videoRef.updateData([
            "viewedCount": FieldValue.increment(Int64(1))
        ])
        viewModel.viewed_videos.insert(video, at: 0)// append(video)
    }
    
    var properties = commonProperties(video: video, user: user, profile: profile)
    properties["Watch Time"] = watchTime as NSNumber
    properties["Watch Percentage"] = percentage as NSNumber
    properties["Watched In Channel"] = watchedIn.id as NSObject
    Amplitude.instance().logEvent(
        "Video Watched",
        withEventProperties: properties)
}

func videoCompleted(for video: Video, with user: User?, profile: Profile?) {
    Amplitude.instance().logEvent(
        "Video Completed",
        withEventProperties: commonProperties(video: video, user: user, profile: profile)
    )
}

func channelClicked(for channel: Channel, with user: User?) {
    var properties = commonProperties(user: user, profile: nil)
    properties["Channel"] = channel.id as NSObject
    
    Amplitude.instance().logEvent(
        "Channel Clicked",
        withEventProperties: properties)
}

func logLogin() {
    Amplitude.instance().logEvent("Log In")
}

func logSignUp(method: String) {
    Amplitude.instance().logEvent(
        "Sign Up",
        withEventProperties: ["Method": method]
    )
}

func logScreenSwitch(to screen: String) {
    Amplitude.instance().logEvent(
        "Screen Switch",
        withEventProperties: [
            "To": screen as NSObject
        ])
}
