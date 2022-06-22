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
    
    /// initialize timers without starting them yet
    var timer1: Timer! = nil        // for the beginning "rotate head left and right" section. Repeats every 8 seconds
    var timer2: Timer! = nil        // for checking the face position. Repeats every 3 seconds
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
        
        /// start the first timer, which reminds the user every 8 seconds to rotate their head
        self.fireTimer1()
    }
    
    // TODO: have a on end function to pause the ar session and invalidate the timer?
    
    
    func fireTimer1() {
        timer1 = Timer(fire: Date(), interval: 8.0, repeats: true, block: { _ in
            self.onTimer1Reset()
        })
        timer1.tolerance = 0.4
        /// start the timer
        RunLoop.current.add(timer1, forMode: .default)
        print("Timer 1 fired!")
    }
    
    func fireTimer2() {
        /// initialize timer
        timer2 = Timer(fire: Date(), interval: 3.0, repeats: true, block: { _ in
            self.onTimer2Reset()
        })
        timer2.tolerance = 0.1
        /// start the timer
        RunLoop.current.add(timer2, forMode: .default)
        print("Timer 2 fired!")
    }
    
    func onTimer1Reset() {
        // future iteration: say specifically what the probelm is. lighting, user needs to rotate a bit further, too far from screen, etc.
        /// remind the user to position their head in the screen
        print("position your head in the center of the screen and rotate it left and right")
        SoundHelper.shared.announce(announcement: SoundHelper.shared.rotateHeadInstructions)
        /// state where the user's face is and orientation
        if facePosition != "" {
            // TODO: change this to use a delegate to determine when the speech has ended, rather than hard coding time values https://stackoverflow.com/questions/37538131/avspeechsynthesizer-detect-when-the-speech-is-finished
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                SoundHelper.shared.announce(announcement: self.facePosition)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    SoundHelper.shared.announce(announcement: self.faceOrientation)
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                SoundHelper.shared.announce(announcement: self.faceOrientation)
            }
        }
    }
    
    func onTimer2Reset() {
        /// check the face orientation and speak when necessary
        if facePosition != "" {
            SoundHelper.shared.announce(announcement: facePosition)
        }
        
        if faceOrientation != "" {
            SoundHelper.shared.announce(announcement: faceOrientation)
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
                if (CheckFaceHelper.shared.checkOrientationOfFace(transformMatrix: faceAnchorTransform) == "") {
                    faceImages[0] = sceneView.snapshot()
                    print("head on image collected")
                }
                // TODO: check to make sure the snapshots are actually good
            }
            if (faceImages[1] == nil) {
                if (CheckFaceHelper.shared.checkOrientationOfFace(transformMatrix: faceAnchorTransform) == CheckFaceHelper.shared.rotatedLeft) {
                    faceImages[1] = sceneView.snapshot()
                    print("rotated left image collected")
                }
            }
            if (faceImages[2] == nil) {
                if (CheckFaceHelper.shared.checkOrientationOfFace(transformMatrix: faceAnchorTransform) == CheckFaceHelper.shared.rotatedRight) {
                    faceImages[2] = sceneView.snapshot()
                    print("rotated right image collected")
                }
            }
            
            
            // MARK: - Finish collecting images
            /// this runs once, right when the images just finished all getting collected
            if (faceImages[0] != nil && faceImages[1] != nil && faceImages[2] != nil) {
                SoundHelper.shared.playSound(soundName: "SuccessSound", dotExt: "wav")
                
                /// hide the instructional image
                DispatchQueue.main.async {
                    self.isNeckImageShowing = false
                }
                
                /// stop timer 1
                timer1.invalidate()
                
                /// initialize and start timer 2
                fireTimer2()
                
                // TODO: convert the images to 2D and store locally? make a function to when the ar session ends, the images get deleted and eveyrhting resets?
            }
        
        }
        facePosition = CheckFaceHelper.shared.checkOrientationOfFace(transformMatrix: faceAnchorTransform)
        // variable to say if the face is not normal. if this variable changes, _____
        // doesn't go back to normal after 5 seconds
        
        faceOrientation = CheckFaceHelper.shared.checkPositionOfFace(transformMatrix: faceAnchorTransform)
        
    }
    
}
