//
//  FirebaseHelpers.swift
//  MakeupGuide
//
//  Created by Lily Jiang on 7/8/22.
//

import SwiftUI
import UIKit
import FirebaseStorage

class FirebaseHelpers {
    public static func upload(imageData: Data, fileName: String) {
        @ObservedObject var generalHelpers = GeneralHelpers.shared
        
//        print("uploading image to Firebase....")
        
        /// root -> face_images -> user UUID -> fileName.jpg
        let ref = Storage.storage().reference().child("face_images").child(generalHelpers.userDefaults.string(forKey: "SessionID")!).child(fileName + ".jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        /// store the image at the specified file location
        ref.putData(imageData) /*{ (metadata, error) in
            print("metadata: \(String(describing: metadata))")
            
            if (error != nil) {
                print("error in posting image to firebase: \(String(describing: error))")
            }
        }*/
        
    }
}
