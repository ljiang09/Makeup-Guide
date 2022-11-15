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
    
    static let shared = FirebaseHelpers()
    
    @Published var userName: String = ""
    
    // MARK: image tester functions
    public func uploadTester(imageData: Data, fileName: String) {
        @ObservedObject var generalHelpers = GeneralHelpers.shared
        
        /// root -> tester_face_images -> user name + UUID -> fileName.png
        let ref = Storage.storage().reference()
                         .child("tester_face_images")
                         .child("\(userName) \(generalHelpers.userDefaults.string(forKey: "SessionID")!)")
                         .child(fileName + ".png")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        
        /// store the image at the specified file location
        ref.putData(imageData, metadata: metadata)
        
        print(metadata)
    }
    
    public func uploadTester(fileName: String, cameraTransform: simd_float4x4, cameraIntrinsics: simd_float3x3) {
        @ObservedObject var generalHelpers = GeneralHelpers.shared
        let sessionData = LogSessionData.shared
        
        /// root -> tester_face_images -> user name + UUID -> fileName.png
        let ref = Storage.storage().reference()
                         .child("tester_face_images")
                         .child("\(userName) \(generalHelpers.userDefaults.string(forKey: "SessionID")!)")
                         .child(fileName + ".txt")
        
        let cameraTransform: [[Float]] = [[cameraTransform[0][0], cameraTransform[0][1], cameraTransform[0][2], cameraTransform[0][3]],
                                          [cameraTransform[1][0], cameraTransform[1][1], cameraTransform[1][2], cameraTransform[1][3]],
                                          [cameraTransform[2][0], cameraTransform[2][1], cameraTransform[2][2], cameraTransform[2][3]],
                                          [cameraTransform[3][0], cameraTransform[3][1], cameraTransform[3][2], cameraTransform[3][3]]]
        let cameraIntrinsics = [[cameraIntrinsics[0][0], cameraIntrinsics[0][1], cameraIntrinsics[0][2]],
                                [cameraIntrinsics[1][0], cameraIntrinsics[1][1], cameraIntrinsics[1][2]],
                                [cameraIntrinsics[2][0], cameraIntrinsics[2][1], cameraIntrinsics[2][2]]]
        
        
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
        
        print("added values into dictionary")
        
        print(jsonDict)
        
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
    
    
    
    
    
    
    // MARK: real functions
    
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
    
    
    /// used to upload ARFaceGeometry data alongside the 4 face textures and 2d images
    public static func upload(fileName: String, cameraTransform: simd_float4x4, cameraIntrinsics: simd_float3x3) {
        @ObservedObject var generalHelpers = GeneralHelpers.shared
        let sessionData = LogSessionData.shared
        
        /// root -> face_images -> user UUID -> fileName.png
        let ref = Storage.storage().reference()
                         .child("face_images")
                         .child(generalHelpers.userDefaults.string(forKey: "SessionID")!)
                         .child(fileName + ".txt")
        
        let cameraTransform: [[Float]] = [[cameraTransform[0][0], cameraTransform[0][1], cameraTransform[0][2], cameraTransform[0][3]],
                                          [cameraTransform[1][0], cameraTransform[1][1], cameraTransform[1][2], cameraTransform[1][3]],
                                          [cameraTransform[2][0], cameraTransform[2][1], cameraTransform[2][2], cameraTransform[2][3]],
                                          [cameraTransform[3][0], cameraTransform[3][1], cameraTransform[3][2], cameraTransform[3][3]]]
        let cameraIntrinsics = [[cameraIntrinsics[0][0], cameraIntrinsics[0][1], cameraIntrinsics[0][2]],
                                [cameraIntrinsics[1][0], cameraIntrinsics[1][1], cameraIntrinsics[1][2]],
                                [cameraIntrinsics[2][0], cameraIntrinsics[2][1], cameraIntrinsics[2][2]]]
        
        
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
        
        print("added values into dictionary")
        
        print(jsonDict)
        
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
