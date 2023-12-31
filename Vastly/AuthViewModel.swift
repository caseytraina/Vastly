//
//  AuthViewModel.swift
//  Vastly
//
//  Created by Casey Traina on 5/21/23.
//

import Foundation
import SwiftUI
import FirebaseAuth
import Firebase
import FirebaseFirestore
import Amplitude


/*
 AuthViewModel handles user authentication through FirebaseAuth. We originally tracked authentication through email/password but now usually solely phone number-based signup. The Auth framework accounts for both, prioritizing phone numbers.
 */

enum AccountType {
    case PhoneNumber
    case Email
}

class AuthViewModel: ObservableObject {
    @Published var user: User? {
        didSet {
            objectWillChange.send()
        }
    }
    
    @Published var isLoggedIn = false
    @Published var error: Error?
    
    @Published var current_user: Profile? = nil
    @Published var searchQueries: [String]?

    @Published var viewedVideosProcessing: Bool = true
    @Published var likedVideosProcessing: Bool = true
    
    // This array shouldn't be used for source of truth for if something has been
    // viewed, for that you should use the viewedVideos collection in the database
    @Published var viewedVideos: [Video] = []
    @Published var likedVideos: [Video] = []
    
    init() {
        listenToAuthState()
    }

    // This function listens for a change in the state of authentication, provided by Firebase docs. Upon a change, this initializes
    // the view model.
    func listenToAuthState() {
        
        Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            DispatchQueue.main.async {
                if let user {
                    self?.user = user
                    self?.isLoggedIn = true

                    Task { [self] in
                        await self?.configureUser(self?.user?.phoneNumber ?? self?.user?.email ?? "")
                    }

                    var AMP_Array: [AnyHashable] = []
                    
                    var id = AMPIdentify()
                        .set((self?.user?.phoneNumber != nil) ? "phone_number" : "email", value: (self?.user?.phoneNumber ?? self?.user?.email ?? "unknown") as NSObject)
                        .set("user_id", value: user.uid as NSObject)
                        .set("name", value: "\(self?.current_user?.firstName) \(self?.current_user?.lastName)" as NSObject)
                        .set("liked_video_count", value: (self?.current_user?.likedVideos?.count ?? 0) as NSObject)
                    
                    if let interests = self?.current_user?.interests {
                        for value in interests {
                            AMP_Array.append(value)
                        }
                    }
                    id?.set("interests", value: AMP_Array as NSObject)
                } else {
                    self?.user = nil
                    self?.isLoggedIn = false
                }
            }
        }
    }

    
    
// email/password sign-in function
    func signIn(email: String, password: String) async throws {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            await configureUser(email)
        } catch {
            self.error = error
            throw error
        }
    }
    
    // text-message verification code for 2FA
    func sendCodeTo(_ phone: String) async {
        PhoneAuthProvider.provider()
          .verifyPhoneNumber(phone, uiDelegate: nil) { verificationID, error in
              if let error = error {
                print("Error validating phone number: \(error)")
                return
              }
              // Code Sent
              UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
          }
    }
    
    // Verification of phone number and verification code combination. Phone number-based sign in function.
    func signInPhone(code: String, completion: @escaping (PhoneSignInResult?) -> Void) {
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
            completion(nil)
            return
        }
        
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: code)
        
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                print("Error verifying number: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let isNewUser = authResult?.additionalUserInfo?.isNewUser {
                
                completion(isNewUser ? PhoneSignInResult.createdAccount : PhoneSignInResult.loggedIn)
                return
            }

            // If there's no error but we can't determine if user is new or existing
            completion(.createdAccount)
        }
    }

// email-based account creation. No longer in use.
    func createAccount(email: String, password: String) async throws {

        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
            await configureUser(email)
        } catch {
            self.error = error
            throw error
        }
    }
    
    // Likes are tracked in Firebase database. This removes a like from the local copy, and then updates firebase to match.
    func removeLikeFrom(_ video: Video) async {
        
        let db = Firestore.firestore()
        
        DispatchQueue.main.async {
            self.likedVideos.removeAll(where: { $0.id == video.id })
        }
        
        let ref = db.collection("users").document(current_user?.phoneNumber ?? current_user?.email ?? "")
        let likedRef = ref.collection("likedVideos").document(video.id)
        
        do {
            try await likedRef.delete()
        } catch {
            print("Error updating liked videos: \(error)")
        }

        await configureUser(current_user?.phoneNumber ?? current_user?.email ?? "")
    }
    
    
    // Likes are tracked in Firebase database. This adds a like from the local copy, and then updates firebase to match.
    func addLikeTo(_ video: Video) async {

        let db = Firestore.firestore()

        let userRef = db.collection("users").document(current_user?.phoneNumber ?? current_user?.email ?? "")
        let videoRef = db.collection("videos").document(video.id)
        let userLikedRef = userRef.collection("likedVideos").document(video.id)
        
        DispatchQueue.main.async {
            self.likedVideos.insert(video, at: 0)
        }
        
        do {
            try await userLikedRef.setData([
                "createdAt": Timestamp(date: Date())
            ])
            
            try await videoRef.updateData([
                "likedCount": FieldValue.increment(Int64(1))
            ])
        } catch {
            print("Error updating liked videos: \(error)")
        }

        await configureUser(current_user?.phoneNumber ?? current_user?.email ?? "")
    }

    // sign out function
    func signOut() async throws {
        do {
            try Auth.auth().signOut()
        } catch {
            self.error = error
            throw error
        }
    }

    // This function adds or updates the user information housed in Firebase database.
    func createUserInFirestore(typeOfUser: AccountType, credential: String, firstName: String, lastName: String, videos: [FirebaseData], interests: [String], additionalInfo: [String: Any] = [:]) async {
        
        let db = Firestore.firestore()
        
        do {
            var firebaseDict : [Int : [String : String?]] = [:]
            
            for i in 0..<videos.count {
                firebaseDict[i] = [
                    "title" : videos[i].title,
                    "author" : videos[i].author,
                    "bio" : videos[i].bio,
                    "location" : videos[i].location,
                    "date" : videos[i].date,
                    "channels" : videos[i].channels?[0],
                    "youtubeURL" : videos[i].youtubeURL
                ]
            }
            
            // Merging data in case you want to add or update more fields in future
            var data: [String: Any] = [typeOfUser == .Email ? "email" : "phoneNumber" : credential, "firstName": firstName, "lastName": lastName, "liked_videos" : [], "interests" : interests, "viewed_videos" : []]
            additionalInfo.forEach { data[$0] = $1 }

            // Upload data
            try await db.collection("users").document(credential).setData(data, merge: true)
            print("User info saved successfully.")
            Analytics.logSignUp(method: "Native In-App")
        } catch {
            print("Failed to save user info: \(error.localizedDescription)")
        }
    }
    
    // This function initializes the view model by declaring the account path in Firebase and retrieving the account info.
    @MainActor
    func configureUser(_ path: String) async {
        let credential = Auth.auth().currentUser?.phoneNumber ?? Auth.auth().currentUser?.email ?? ""
        
        let db = Firestore.firestore()
        let storageRef = db.collection("users").document(path)
        
        do {
            self.current_user = try await fetch(docRef: storageRef)
        } catch {
            print("error getting user: \(error)")
        }
    }
    
    func addToSearch(_ query: String) async {
        
        if (self.searchQueries != nil) {
            if !(self.searchQueries?.contains(where: {$0 == query}) ?? false) {
                DispatchQueue.main.async {
                    self.searchQueries?.append(query)
                }
            }
        } else {
            DispatchQueue.main.async {
                self.searchQueries = [query]
            }
        }
        
        let db = Firestore.firestore()
        let storageRef = db.collection("users").document(current_user?.phoneNumber ?? current_user?.email ?? "")
        
        do {
            try await storageRef.collection("searchHistory").addDocument(data: [
                "createdAt" : Date(),
                "query" : query
            ])
        } catch {
            print("error uploading query: \(error)")
        }
    }
    
    func removeFromSearch(_ query: String) async {
        DispatchQueue.main.async {
            self.searchQueries?.removeAll(where: {$0 == query})
        }
        
        let db = Firestore.firestore()
        let storageRef = db.collection("users").document(current_user?.phoneNumber ?? current_user?.email ?? "")

        do {
            
            let docs = try await storageRef.collection("searchHistory").whereField("query", isEqualTo: query).getDocuments().documents
            
            for doc in docs {
                let ID = doc.documentID
                
                let docs = try await storageRef.collection("searchHistory").document(ID).delete()
            
            }
            
        } catch {
            print("Error deleting query: \(query)")
        }
        
        
    }

    // This function retrieves and returns the user profile from firebase, given a database path input. This returns type "Profile"
    func fetch(docRef: DocumentReference) async throws -> Profile {
        do {
            let documentSnapshot = try await docRef.getDocument()
            let data = documentSnapshot.data()
                
            // TODO: this can be removed when enough people have logged in to the app and data
            // has been moved over
            // migrate old likes schema to new likes
            let likedVideos = try await docRef.collection("likedVideos")
                .order(by: "createdAt", descending: true)
                .limit(to: 25)
                .getDocuments().documents
            let newLikedDocumentIds = likedVideos.map{ v in v.documentID }
            
            // migrate old views schema to new views
            let viewedVideos = try await docRef.collection("viewedVideos")
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
                .getDocuments().documents
            let newViewedDocumentIds = viewedVideos.map{ v in v.documentID }
            
            // migrate old views schema to new views
            let searchDocs = try await docRef.collection("searchHistory")
                .order(by: "createdAt", descending: true)
                .limit(to: 6)
                .getDocuments().documents
            var searchQueries: [String] = []
            
            for doc in searchDocs {
                let data = doc.data()
                
                let query = data["query"] as! String
                
                searchQueries.append(query)
            }
            
            if (self.searchQueries != nil) {
                for query in searchQueries {
                    DispatchQueue.main.async {
                        self.searchQueries?.append(query)
                    }
                }
            } else {
                self.searchQueries = searchQueries
            }
            
            
            let profile = Profile(firstName: data?["firstName"] as? String ?? nil,
                                  lastName: data?["lastName"] as? String ?? nil,
                                  email: data?["email"] as? String ?? nil,
                                  phoneNumber: data?["phoneNumber"] as? String ?? nil,
                                  interests: data?["interests"] as? [String] ?? nil,
                                  likedVideos: newLikedDocumentIds,
                                  viewedVideos: newViewedDocumentIds)
            return profile
        } catch let error {
            print("Error fetching profile data: \(error)")
            throw error
        }
    }
    
    func fetchLikedVideos(authors: [Author]) async {
        if let liked_videos = self.current_user?.likedVideos {
            let db = Firestore.firestore()
            let ref = db.collection("videos")
            
            for id in liked_videos {
                do {
                    let doc = try await ref.document(id).getDocument()
                    if doc.exists {
                        print("Doc Found for \(id)")
                        
                        let data = doc.data()
                        
                        let video = Video.resultToVideo(id: id, data: data, authors: authors)
                        if let video {
                            if !self.likedVideos.contains(where: { $0.id == video.id }) {
                                DispatchQueue.main.async {
                                    self.likedVideos.append(video)
                                }
                            }
                        }
                        
                        if self.likedVideos.count > 5 {
                            DispatchQueue.main.async {
                                self.likedVideosProcessing = false
                            }
                        }
                        
                    } else {
                        print("Doc not found for \(id)")
                    }
                    
                } catch {
                    print("Error getting viewing history: \(error)")
                }
            }
        }
        
        DispatchQueue.main.async {
            self.likedVideosProcessing = false
        }
    }
    
    // Populates self.viewedVideos to be shown in the history page
    func fetchViewedVideos(authors: [Author]) async {
        if let viewed_videos = self.current_user?.viewedVideos {
            let db = Firestore.firestore()
            let ref = db.collection("videos")
            for id in viewed_videos {
                do {
                    let doc = try await ref.document(id).getDocument()
                    if doc.exists {
                        print("Doc Found for \(id)")
                        
                        let data = doc.data()
                        
                        let video = Video.resultToVideo(id: id, data: data, authors: authors)
                        
                        if let video {
                            if !self.viewedVideos.contains(where: { $0.id == video.id }) {
                                DispatchQueue.main.async {
                                    self.viewedVideos.append(video)
                                }
                            }
                        }
                        
                        if self.viewedVideos.count > 5 {
                            DispatchQueue.main.async {
                                self.viewedVideosProcessing = false
                            }
                        }
                        
                    } else {
                        print("Doc not found for \(id)")
                    }
                    
                } catch {
                    print("Error getting viewing history: \(error)")
                }
            }
        }
        DispatchQueue.main.async {
            self.viewedVideosProcessing = false
        }
    }
    
}
