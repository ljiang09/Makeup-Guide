/*
ARSessionManager.swift
MakeupGuide
Created by Lily Jiang on 6/14/22

This file manages the AR session and triggers commands such as informing the user where their face is on the screen via audio commands.
*/

import SwiftUI
import SceneKit
import ARKit

class ARSessionManager: NSObject, ObservableObject {
    let sceneView = ARSCNView(frame: .zero)
    
    static var shared: ARSessionManager = ARSessionManager()
    
    @Published var isNeckImageShowing: Bool
    var faceAnchorTransform: [[Float]] = [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
    var faceImages: [UIImage?] = [nil, nil, nil]
    
    /// initialize timer without starting it yet
    var timer: Timer! = nil
    var facePosition: String = ""
    var faceOrientation: String = ""
    
    private override init() {
        isNeckImageShowing = true
        
        super.init()
        sceneView.session.run(ARFaceTrackingConfiguration())
        sceneView.delegate = self
        
        /// after half a second, state the instructions for the user to rotate their head around and such
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SoundHelper.shared.announce(announcement: SoundHelper.shared.rotateHeadInstructions)
        }
    }
    
    // TODO: have a on end function to pause the ar session and invalidate the timer?
    
    
    func fireTimer() {
        /// initialize timer
        timer = Timer(fire: Date(), interval: 3.0, repeats: true, block: { _ in
            self.onTimerReset()
        })
        timer.tolerance = 0.1
        
        /// start the timer
        RunLoop.current.add(timer, forMode: .default)
        print("Timer fired!")
    }
    
    func onTimerReset() {
        /// check the face orientation and speak when necessary
//        print("timer reset")
        
        if facePosition != "" {
            print(facePosition)
        }
        
        if faceOrientation != "" {
            print(faceOrientation)
        }
    }
}


// MARK: - SceneKit delegate
extension ARSessionManager: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        /// Make sure the device supports Metal
        guard let device = sceneView.device else { return nil }

        /// Create the face geometry
        let faceGeometry = ARSCNFaceGeometry(device: device)

        /// Create a SceneKit node to be rendered
        let node = SCNNode(geometry: faceGeometry)

        /// Set the fill mode for the node to be lines. This makes the mesh mask
        node.geometry?.firstMaterial?.fillMode = .lines

        return node
    }
    
    
    /// this makes the mesh mask move as you blink, open mouth, etc.
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        /// check to make sure the face anchor and geometry being updated are the correct types (`ARFaceAnchor` and `ARSCNFaceGeometry`)
        guard let faceAnchor = anchor as? ARFaceAnchor,
              let faceGeometry = node.geometry as? ARSCNFaceGeometry else { return }
        
        /// Update `ARSCNFaceGeometry` using the `ARFaceGeometry` corresponding to the `ARFaceAnchor`
        faceGeometry.update(from: faceAnchor.geometry)
        
        /// change the coordinate system to be the camera (mathematically)
        let x = changeCoordinates(currentFaceTransform: faceAnchor.transform, frame: sceneView.session.currentFrame!)
        faceAnchorTransform = [[x[0][0], x[0][1], x[0][2], x[0][3]],     // column 0
                               [x[1][0], x[1][1], x[1][2], x[1][3]],
                               [x[2][0], x[2][1], x[2][2], x[2][3]],
                               [x[3][0], x[3][1], x[3][2], x[3][3]]]
        
        
        
        
        
        /// every frame, check if we have successfully collected the images. If not, try to collect them
        if (faceImages[0] == nil || faceImages[1] == nil || faceImages[2] == nil) {
            if (faceImages[0] == nil) {
                if (CheckFaceHelper.checkOrientationOfFace(transformMatrix: faceAnchorTransform) == "") {
                    faceImages[0] = sceneView.snapshot()
                    print("head on image collected")
                }
                // TODO: check to make sure the snapshots are actually good
            }
            if (faceImages[1] == nil) {
                if (CheckFaceHelper.checkOrientationOfFace(transformMatrix: faceAnchorTransform) == "Face is rotated Left") {
                    faceImages[1] = sceneView.snapshot()
                    print("rotated left image collected")
                }
            }
            if (faceImages[2] == nil) {
                if (CheckFaceHelper.checkOrientationOfFace(transformMatrix: faceAnchorTransform) == "Face is rotated Right") {
                    faceImages[2] = sceneView.snapshot()
                    print("rotated right image collected")
                }
            }
            
            // MARK: - Finish collecting images
            /// this runs once, right when the images just finished all getting collected
            if (faceImages[0] != nil && faceImages[1] != nil && faceImages[2] != nil) {
                SoundHelper.shared.playSound(soundName: "SuccessSound", dotExt: "wav")
                // TODO: this plays but suddenly stops playing. it cuts out like right when it begins
                
                DispatchQueue.main.async {
                    self.isNeckImageShowing = false
                }
                
                /// initialize and start the timer
                fireTimer()
                
                // TODO: convert the images to 2D and store locally? make a function to when the ar session ends, the images get deleted and eveyrhting resets?
            }
        
        }
        else {
            facePosition = CheckFaceHelper.checkOrientationOfFace(transformMatrix: faceAnchorTransform)
            // variable to say if the face is not normal. if this variable changes, _____
            // doesn't go back to normal after 5 seconds
            
            faceOrientation = CheckFaceHelper.checkPositionOfFace(transformMatrix: faceAnchorTransform)
        }
        
    }
    
}
