////
////  GetFaceBaseline.swift
////  MakeupGuide02
////
////  Created by Lily Jiang on 6/13/22.
////
//
//import UIKit
//import ARKit
//
///// this is used to guide the user on how to place their face to best get images of teir face to compare against them wiht makeup on
//class CollectFaceImages {
//
//    // TODO: change the return type of all these functions when you figure out how the images will be collected
//    /// this function cannot be static because it has values that change with every instance.
//    func collectFaceImages(transformMatrix: [[Float]]) -> Void {
//        var headOnImage: UIImage? = nil;
//        var leftSideImage: UIImage? = nil;
//        var rightSideImage: UIImage? = nil;
//
//        var timerFinished: Bool = false;
//
//
//        print("Slowly move your head side to side")
//
//        /// start a timer for 10 seconds, with a tolerance of 1 second, on a secondary thread (so UI interactions don't affect the time)
//        var timer = Timer()
//        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { timer in
//            timerFinished = true
//        }
//        timer.tolerance = 1
//        RunLoop.current.add(timer, forMode: .common)
//
//
//        /// loop through until you have images for all of them
//        while (headOnImage == nil && leftSideImage == nil && rightSideImage == nil) {
//            // TODO: show an animation continuously
//
//            if (headOnImage == nil) {
//                print("Attempting to collect head on image")
//                headOnImage = collectOneImage(transformMatrix: transformMatrix, orientation: 0)
//            }
//            if (leftSideImage == nil) {
//                print("Attempting to collect left side image")
//                leftSideImage = collectOneImage(transformMatrix: transformMatrix, orientation: 1)
//            }
//            if (rightSideImage == nil) {
//                print("Attempting to collect right side image")
//                rightSideImage = collectOneImage(transformMatrix: transformMatrix, orientation: 2)
//            }
//
//            if (timerFinished) {
//                print("Please try again with better lighting")
//                // TODO: restart the timer again
//            }
//        }
//
//        // now that you have the 3 images, end the animation with a check mark image or something
//    }
//
//
//    /// this attempts to collect one image and returns it.
//    private func collectOneImage(transformMatrix: [[Float]], orientation: Int) -> UIImage? {
//        // TODO: somehow determine the orientation of the face at this instance?
//            // have a switch statement to figure out which orientation the face is at this specific moment in time
//        switch (orientation) {
//        case 0:
//            // if head is straight on, CheckFaceHelper.checkOrientationOfFace()
//            return sceneView.snapshot()
//            // else return nil
//        default:
//            return nil
//        }
//        // if the head is straight on and orientation = 0, return the snapshot
//        // if the head is facing left and orientation = 1, return the snapshot
//        // if the head is facing right and orientation = 2, return the snapshot
//        // else, return nil
//
//
//        // if the face is at a specified rotation point (use your transform matrix to determine, take a picture. If that picture is blurry, don't sve the image and inform the user to stop moving so fast
//        // if it is NOT blurry, save the image and store it in an array
//            // if it is too blurry, start over and tell the user to roll their head slower
//    }
//
//
//    // probably like 4 shots should be taken. For each shot, one specific area of the face should be focused on so the 2d mesh will override everything in that specific part of the 2d texture mesh. Then in the end, 1 very accurate mesh will be created?
//    // alternatively, have multiple meshes and label them for which angle of the face was taken from. Then when the user is applying makeup, just compare directly yo that face mesh (with priority areas fo the textyre depnending on the angle of the face).
//
//
//    // ahve user position face in the first position
//    // when it is good for 1 second, take snapshot and run algorithm to put the triangles onto a 2d texture
//    // repeat x3 or whatever to get multiple angles...
//    // store these images in the app but locally. somehow
//
//
//
//
//
//
//
//}
