//
//  ImageCollectionManager.swift
//  MakeupGuide
//
//  Created by Lily Jiang on 10/5/22.
//

import UIKit


/// holds all the functions and actions that are called in the AR session manager
//class ImageCollectionManager {
//    let arManager = ARSessionManager.shared
//
//    // TODO: if this function returns nil, don't do anything. If it collects the image successfully and returns a UIImage, in the ar session manager class, make the `imageBeingCollected = nil` (// reset the value so we're not looking for other images once this one is acquired)
//    static func collectImages(imageBeingCollected: String, faceTransform: [[Float]]) -> UIImage? {
//        // determine which, if any, images are attempting to be collected
//        switch imageBeingCollected {
//        case ARSessionManager.facePositions[0]:
//
//
//            // TODO: if the positioning of the face is precise, then collect the image and set imagebeingcollected to nil
////            self.soundHelper.playSound(soundName: "SuccessSound", dotExt: "wav")
////            DispatchQueue.main.async {
////                self.isCheckMakeupButtonShowing = true
////            }
//            break
//        case ARSessionManager.facePositions[1]:
//            print(ARSessionManager.facePositions[1])
//        case ARSessionManager.facePositions[2]:
//            print(ARSessionManager.facePositions[2])
//        case ARSessionManager.facePositions[3]:
//            print(ARSessionManager.facePositions[3])
//
//            // since this is the last image to be collected, when it is, run an annoucnement telling them to apply makeup and click the "check makeup" button when they're done. do this in an async function with a delay of 0.01 so it actually works
//        default:
//            print("default case reached")
//        }
//
//
//
//    }
//}
