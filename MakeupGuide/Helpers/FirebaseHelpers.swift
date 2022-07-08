/*
 FirebaseHelpers.swift
MakeupGuide
Created by Lily Jiang on 7/8/22

This file holds helper functions for communicating with Firebase.
    These functions are all static so they can be accessed without an instance of the class
*/

import SwiftUI
import UIKit
import FirebaseStorage

class FirebaseHelpers {
    
    /// uploads an image to Firebase Storage
    ///
    /// - Parameters:
    ///     - imageData: represents the image as a Data object
    ///     - fileName: represents the name of the file that the image will be saved to in the Firebase hierarchy
    ///
    /// - Returns:
    ///     - nothing
    public static func upload(imageData: Data, fileName: String) {
        @ObservedObject var generalHelpers = GeneralHelpers.shared
        
        /// root -> face_images -> user UUID -> fileName.jpg
        let ref = Storage.storage().reference().child("face_images").child(generalHelpers.userDefaults.string(forKey: "SessionID")!).child(fileName + ".jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        /// store the image at the specified file location
        ref.putData(imageData)
    }
}
