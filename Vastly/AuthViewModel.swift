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
    @Published var liked_videos: [String] = []
    
    var viewModel: VideoViewModel?
    
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
                        self?.viewModel = VideoViewModel(authModel: self ?? AuthViewModel())
                    }

                    var AMP_Array: [AnyHashable] = []
                    
                    var id = AMPIdentify()
                        .set((self?.user?.phoneNumber != nil) ? "phone_number" : "email", value: (self?.user?.phoneNumber ?? self?.user?.email ?? "unknown") as NSObject)
                        .set("user_id", value: user.uid as NSObject)
                        .set("name", value: "\(self?.current_user?.firstName) \(self?.current_user?.lastName)" as NSObject)
                        .set("liked_video_count", value: (self?.current_user?.liked_videos?.count ?? 0) as NSObject)
                    
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
            self.liked_videos.removeAll(where: { $0 == video.title })
        }
        
        let ref = db.collection("users").document(current_user?.phoneNumber ?? current_user?.email ?? "")
        
        do {
            try await ref.updateData([
                "liked_videos" : FieldValue.arrayRemove([video.title])
            ])
        } catch {
            print("Error updating liked videos: \(error)")
        }

        await configureUser(current_user?.phoneNumber ?? current_user?.email ?? "")

    }
    // Likes are tracked in Firebase database. This adds a like from the local copy, and then updates firebase to match.
    func addLikeTo(_ video: Video) async {

                
        let db = Firestore.firestore()

        let ref = db.collection("users").document(current_user?.phoneNumber ?? current_user?.email ?? "")
        
        DispatchQueue.main.async {
            self.liked_videos.append(video.title)
        }
        
        do {
            try await ref.updateData([
                "liked_videos" : FieldValue.arrayUnion([video.title])
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
            logSignUp(method: "Native In-App")
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
            print(error)
        }
    }

    // This function retrieves and returns the user profile from firebase, given a database path input. This returns type "Profile"
    func fetch(docRef: DocumentReference) async throws -> Profile {
        do {
            let documentSnapshot = try await docRef.getDocument()
            
            let data = documentSnapshot.data()
            
            let profile = Profile(firstName: data?["firstName"] as? String ?? nil, lastName: data?["lastName"] as? String ?? nil, email: data?["email"] as? String ?? nil, phoneNumber: data?["phoneNumber"] as? String ?? nil, liked_videos: data?["liked_videos"] as? [String] ?? nil, interests: data?["interests"] as? [String] ?? nil, viewed_videos: data?["viewed_videos"] as? [String] ?? nil)
            DispatchQueue.main.async { [data] in
                self.liked_videos = data?["liked_videos"] as? [String] ?? []
            }

            print(profile)
            return profile
        } catch let error {
            print("Error fetching profile data: \(error)")
            throw error
        }
    }
    
    
}
