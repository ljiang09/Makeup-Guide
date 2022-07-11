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
        let ref = Storage.storage().reference()
                         .child("face_images")
                         .child(generalHelpers.userDefaults.string(forKey: "SessionID")!)
                         .child(fileName + ".jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        /// store the image at the specified file location
        ref.putData(imageData)
    }
    
    
    public static func uploadSessionLog() -> URL {
        @ObservedObject var sessionData = LogSessionData.shared
        @ObservedObject var generalHelpers = GeneralHelpers.shared
        
        
        // encode into json
        // send that json Data object to firebase
        
//        do {
//            let employeeData = try JSONEncoder().encode(Employee(name: "abc def", ssn: "123456789"))
//            UserDefaults.standard.set(employeeData, forKey: employeeDataKey)
//        } catch {
//            print(error.localizedDescription)
//        }
        
        let documents: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url: URL = documents.appendingPathComponent("sessionLog.txt")
        
        if (FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)) {
            print("File created successfully.")
        } else {
            print("File not created.")
        }
        
        do {
            try sessionData.faceGeometries.description.write(to: url, atomically: true, encoding: String.Encoding.utf8)
//            print("geometries written to file")
            try sessionData.facePosAndOrient.description.write(to: url, atomically: true, encoding: String.Encoding.utf8)
//            print("position and orientation written to file")
            try sessionData.voiceovers.description.write(to: url, atomically: true, encoding: String.Encoding.utf8)
//            print("voiceovers written to file")
            try sessionData.buttonsClicked.description.write(to: url, atomically: true, encoding: String.Encoding.utf8)
//            print("clicked buttons written to file")
        } catch {
            print("error with writing to file", error)
        }
        
        let ref = Storage.storage().reference()
                         .child("analytics")
                         .child(generalHelpers.userDefaults.string(forKey: "SessionID")!)
                         .child("analytics_file")
        
        ref.putFile(from: url, metadata: nil) { (metadata, error) in
            guard metadata != nil else {
                print(error ?? "Error with uploading session data to firebase")
                return
            }
            
            /// if successful, clear sessionData variables
            sessionData.faceGeometries.removeAll()
            sessionData.facePosAndOrient.removeAll()
            sessionData.voiceovers.removeAll()
            sessionData.buttonsClicked.removeAll()
            print("local data is cleared")
        }
        print("successful upload")
        
        let value: UInt8 = 123
        let data = Data([value])
        ref.putData(data)
        
        return url
    }
}
