//
//  VastlyApp.swift
//  Vastly
//
//  Created by Casey Traina on 5/9/23.
//

import SwiftUI
import AVKit

import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

import Amplitude

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      FirebaseApp.configure()
      
      let db = Firestore.firestore()
      
      let audioSession = AVAudioSession.sharedInstance()
      do {
          try audioSession.setCategory(.playback, mode: AVAudioSession.Mode.default)
          try audioSession.setActive(true)
      } catch let error as NSError {
          print("Setting category to AVAudioSessionCategoryPlayback failed: \(error)")
      }
      
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
          guard granted else { return }
          DispatchQueue.main.async {
              application.registerForRemoteNotifications()
          }
      }
      
      
//      Amplitude.instance().defaultTracking = AMPDefaultTrackingOptions.initWithAllEnabled()
      
      Amplitude.instance().defaultTracking = AMPDefaultTrackingOptions.initWithSessions(
          true,
          appLifecycles: true,
          deepLinks: true,
          screenViews: false
      )
      
      Amplitude.instance().initializeApiKey("3a8f88476df1fe3695ac70ddf404d4c0")
      // Log an event
      Amplitude.instance().logEvent("app_start")
      
      return true
      
  }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification notification: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        if Auth.auth().canHandleNotification(notification) {
            completionHandler(.noData)
            return
        }
        // This notification is not auth related, developer should handle it.
        print(notification)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Handle the registration to receive notifications.
        print("Successfully registered for notifications")

    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Handle the failure of registration.
        print("Failed to register for notifications: \(error)")
    }

}

@main
struct VastlyApp: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authModel = AuthViewModel()
//    @StateObject var videoViewModel = VideoViewModel()

//    @StateObject var playerManager = VideoPlayerManager(videos: VideoViewMode)
    
    
    
  var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
              .environmentObject(authModel)
//              .environmentObject(videoViewModel)
//              .environmentObject(playerManager)

      }
    }
  }
}
