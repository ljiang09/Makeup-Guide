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
import ARKit

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
        
        /// root -> face_images -> user UUID -> fileName.png
        let ref = Storage.storage().reference()
                         .child("face_images")
                         .child(generalHelpers.userDefaults.string(forKey: "SessionID")!)
                         .child(fileName + ".png")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        
        /// store the image at the specified file location
        ref.putData(imageData, metadata: metadata)
        
        print(metadata)
    }
    
    
    // temporarily used to upload ARFaceGeometry data alongside the 4 face textures and 2d images
    public static func upload(fileName: String, cameraTransform: simd_float4x4, cameraIntrinsics: simd_float3x3) {
        @ObservedObject var generalHelpers = GeneralHelpers.shared
        let sessionData = LogSessionData.shared
        
        /// root -> face_images -> user UUID -> fileName.png
        let ref = Storage.storage().reference()
                         .child("face_images")
                         .child(generalHelpers.userDefaults.string(forKey: "SessionID")!)
                         .child(fileName + ".txt")
        
        
        let jsonDict = ["faceGeometries": sessionData.faceGeometries.map({ faceGeometry in
                             ["timestamp": faceGeometry.0,
                              "vertices": faceGeometry.1.vertices.map({ vertex in
                                  [vertex.x, vertex.y, vertex.z]
                              }),
                              "textureCoords": faceGeometry.1.textureCoordinates.map({ coords in
                                 [coords.x, coords.y]
                              }),
                              "triangleCount": faceGeometry.1.triangleCount,
                              "triangleIndices": faceGeometry.1.triangleIndices
                             ]
                        }),
                        "facePosAndOrient": sessionData.facePosAndOrient.map({ value in
                            ["timestamp": value.0,
                             "transformMatrix": value.1,
                             "positionDeclaration": value.2,
                             "orientationDeclaration": value.3
                            ]
                        }),
                        "cameraTransform": cameraTransform,
                        "cameraIntrinsics": cameraIntrinsics
        ] as [String : Any]
        
        print("\(#function) \(#line) added values into dictionary")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDict)
            
            ref.putData(jsonData, metadata: nil) { (metadata, error) in
                guard metadata != nil else {
                    print(error ?? "Error with uploading debug data to firebase")
                    return
                }
                print("successfully uploaded json \(String(describing: metadata))")
            }
        } catch {
            print(error)
        }
    }
    
    
    public static func uploadSessionLog(int: Int) {
        let sessionData = LogSessionData.shared
        let generalHelpers = GeneralHelpers.shared
        
        
        let ref = Storage.storage().reference()
                         .child("analytics")
                         .child(generalHelpers.userDefaults.string(forKey: "SessionID")!)
                         .child("analytics_file_\(int).txt")
        
        
        let jsonDict = ["faceGeometries": sessionData.faceGeometries.map({ faceGeometry in
                             ["timestamp": faceGeometry.0,
                              "vertices": faceGeometry.1.vertices.map({ vertex in
                                  [vertex.x, vertex.y, vertex.z]
                              }),
                              "textureCoords": faceGeometry.1.textureCoordinates.map({ coords in
                                 [coords.x, coords.y]
                              }),
                              "triangleCount": faceGeometry.1.triangleCount,
                              "triangleIndices": faceGeometry.1.triangleIndices
                             ]
                        }),
                        "facePosAndOrient": sessionData.facePosAndOrient.map({ value in
                            ["timestamp": value.0,
                             "transformMatrix": value.1,
                             "positionDeclaration": value.2,
                             "orientationDeclaration": value.3
                            ]
                        }),
                        "voiceovers": sessionData.voiceovers.map({ value in
                            ["timestamp": value.0,
                             "voiceoverLine": value.1
                            ]
                        }),
                        "buttonsClicked": sessionData.buttonsClicked.map({ value in
                            ["timestamp": value.0,
                             "buttonClicked": value.1
                            ]
                        }),
                        "imagesCollected": sessionData.imageCollection.map({ value in
                            ["timestamp": value.0,
                             "whichImage": value.1]
                        })
                        ]
        
//        print("compiled json data successfully")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDict)
            
            ref.putData(jsonData, metadata: nil) { (metadata, error) in
                guard metadata != nil else {
                    print(error ?? "Error with uploading debug data to firebase")
                    return
                }
                print("successfully uploaded json \(String(describing: metadata))")
            }
        } catch {
            print(error)
        }
    }
}
