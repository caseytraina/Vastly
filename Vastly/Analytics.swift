//
//  Analytics.swift
//  Vastly
//
//  Created by Casey Traina on 6/26/23.
//

import Foundation
import Firebase
import Amplitude

class Analytics {
    static func logScreenSwitch(to screen: String) {
        Amplitude.instance().logEvent(
            "Screen Switch",
            withEventProperties: [
                "To": screen as NSObject
            ])
    }

    static func logSignUp(method: String) {
        Amplitude.instance().logEvent(
            "Sign Up",
            withEventProperties: ["Method": method]
        )
    }
    
    static func videoWatched(watchTime: Double,
                             percentageWatched: Double,
                             video: Video,
                             user: User?, 
                             profile: Profile?,
                             watchedIn: Channel) {
        var properties = commonProperties(video: video, user: user, profile: profile)
        properties["Watch Time"] = watchTime as NSNumber
        properties["Watch Percentage"] = percentageWatched as NSNumber
        properties["Watched In Channel"] = watchedIn.id as NSObject
        Amplitude.instance().logEvent(
            "Video Watched",
            withEventProperties: properties)
    }
    
    
    static func videoClicked(video: Video,
                             user: User?,
                             profile: Profile?,
                             watchedIn: Channel) {
        var properties = commonProperties(video: video, user: user, profile: profile)
        properties["Watched In Channel"] = watchedIn.id as NSObject
        Amplitude.instance().logEvent(
            "Video Clicked",
            withEventProperties: properties
        )
    }
    
    static func channelClicked(channel: Channel,
                               user: User?,
                               profile: Profile?) {
        var properties = commonProperties(user: user, profile: profile)
        properties["Channel"] = channel.id as NSObject
        
        Amplitude.instance().logEvent(
            "Channel Clicked",
            withEventProperties: properties)
    }

    private static func commonProperties(video: Video) -> [String: NSObject] {
        return [
            "Video ID": video.id as NSObject,
            "Video Title": video.title as NSObject,
            "Video Channels": video.channels as NSObject,
            "Author": (video.author.name ?? "") as NSObject
        ]
    }

    private static func commonProperties(user: User?, profile: Profile?) -> [String: NSObject] {
        return [
            "User ID": (user?.uid ?? "") as NSObject,
            "Name": (profile?.name() ?? "") as NSObject
        ]
    }

    private static func commonProperties(video: Video, user: User?, profile: Profile?) -> [String: NSObject] {
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
}
