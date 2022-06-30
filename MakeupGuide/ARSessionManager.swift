/*
ARSessionManager.swift
MakeupGuide
Created by Lily Jiang on 6/14/22

This file manages the AR session and triggers commands such as informing the user where their face is on the screen via audio commands.
*/

import SwiftUI
import SceneKit
import ARKit
import UIKit

class ARSessionManager: NSObject, ObservableObject {
    // variables for the UV unwrapping
    private var faceUvGenerator: FaceTextureGenerator!
    private var scnFaceGeometry: ARSCNFaceGeometry!
    private let faceTextureSize = 1024 //px
    
    let sceneView = ARSCNView(frame: .zero)
    
    static var shared: ARSessionManager = ARSessionManager()
    
    @Published var isNeckImageShowing: Bool
    var faceAnchorTransform: [[Float]] = [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
    var faceImages: [UIImage?] = [nil, nil, nil]
    
    var facePosition: String = "blank"
    var faceOrientation: String = "blank"
    
    /// initialize timers without starting them yet
    var timer2: Timer! = nil        // for the beginning "rotate head left and right" section. Repeats every 8 seconds
    var timer3: Timer! = nil        // for checking the face position. Repeats every 3 seconds
    
    private override init() {
        isNeckImageShowing = false
        
        super.init()
        sceneView.session.run(ARFaceTrackingConfiguration())
        sceneView.delegate = self
        
        
        // TODO: test whether having fill mesh true/false is more accurate
        self.scnFaceGeometry = ARSCNFaceGeometry(device: self.sceneView.device!, fillMesh: true)
        
        self.faceUvGenerator = FaceTextureGenerator(
            device: self.sceneView.device!,
            library: self.sceneView.device!.makeDefaultLibrary()!,      // this compiles all metal files into one library
            viewportSize: UIScreen.main.bounds.size,
            face: self.scnFaceGeometry,
            textureSize: faceTextureSize)
        
        
        
        /// after half a second, call function to check whether the user's face is positioned well in the screen.
        /// once the face is centered, run the next phase of face rotation/snapshot gathering
        /// note: "centering the face" (aka running the closure) also makes the code collect a head on image which is cool
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkFaceUntilRepositioned(completion: {
                SoundHelper.shared.playSound(soundName: "SuccessSound", dotExt: "wav")
                // TODO: show the check mark image here
                
                /// if the user successfully positions their face (which is when this completion runs), state the instructions after 0.8 s for the user to rotate their head around and such
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.isNeckImageShowing = true
                    SoundHelper.shared.announce(announcement: SoundHelper.shared.rotateHeadInstructions)
                    
                    /// start the 2nd timer, which reminds the user every 8 seconds to rotate their head
                    self.firetimer2()
                }
            })
        }
        
    }
    
    // TODO: have a on end function to pause the ar session and invalidate the timer?
    
    
    /// this function is intended to run at the beginning of the app lifecycle
    /// it is also optionally called whenever the user's face is continually not centered
    ///
    /// it continually checks the face position until the face is centered and then runs the closure
    func checkFaceUntilRepositioned(completion: @escaping () -> Void) {
        let timer1: Timer = Timer(fire: Date(), interval: 3.0, repeats: true, block: { timer1 in
            if ((self.facePosition == "") && (self.faceOrientation == "")) {
                timer1.invalidate()
                completion()
            }
            
            if ((self.facePosition != "") || (self.facePosition != "blank")) {
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
        })
        timer1.tolerance = 0.2
        RunLoop.current.add(timer1, forMode: .default)
    }
    
    
    
    func firetimer2() {
        timer2 = Timer(fire: Date(), interval: 8.0, repeats: true, block: { _ in
            self.ontimer2Reset()
        })
        timer2.tolerance = 0.4
        /// start the timer
        RunLoop.current.add(timer2, forMode: .default)
        print("Timer 1 fired!")
    }
    
    func firetimer3() {
        /// initialize timer
        timer3 = Timer(fire: Date(), interval: 3.0, repeats: true, block: { _ in
            self.ontimer3Reset()
        })
        timer3.tolerance = 0.1
        /// start the timer
        RunLoop.current.add(timer3, forMode: .default)
        print("Timer 2 fired!")
    }
    
    func ontimer2Reset() {
        // future iteration: say specifically what the probelm is. lighting, user needs to rotate a bit further, too far from screen, etc.
        /// remind the user to position their head in the screen
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
    
    func ontimer3Reset() {
        /// check the face orientation and speak when necessary
        if facePosition != "" {
            SoundHelper.shared.announce(announcement: facePosition)
        }
        
        if faceOrientation != "" {
            SoundHelper.shared.announce(announcement: faceOrientation)
        }
    }
    
    
    /// just for debugging purposes
    public func exportTextureMapToPhotos() {
        if let uiImage = textureToImage(faceUvGenerator.texture) {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            print("export saved to photos")
        } else {
            print("export failed")
        }
    }
    
}


// MARK: - SceneKit delegate
extension ARSessionManager: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        /// Make sure the device supports Metal
//        guard let device = sceneView.device else { return nil }

        /// Create the face geometry
//        let faceGeometry = ARSCNFaceGeometry(device: device)

        /// Create a SceneKit node to be rendered
//        let node = SCNNode(geometry: faceGeometry)

        /// Set the fill mode for the node to be lines. This makes the mesh mask
//        node.geometry?.firstMaterial?.fillMode = .lines
        
//        return node
        
        
        /// replaced the old code that made a mesh on your face, with the code that was in the HeadShot renderer()
        guard anchor is ARFaceAnchor else {
            return nil
        }
        /// this is for the face UV unwrapping. Unsure if its needed
        let node = SCNNode(geometry: scnFaceGeometry)
        scnFaceGeometry.firstMaterial?.diffuse.contents = textureToImage(faceUvGenerator.texture)   // this line of code works with other images, not sure about this MTLTexture tho. Perhaps need to convert it to Image - test this current code out!!
        return node
    }
    
    
    /// this makes the mesh mask move as you blink, open mouth, etc.
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        /// check to make sure the face anchor and geometry being updated are the correct types (`ARFaceAnchor` and `ARSCNFaceGeometry`)
        guard let faceAnchor = anchor as? ARFaceAnchor,
              let frame = sceneView.session.currentFrame,
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
                    DispatchQueue.main.async {
                        self.exportTextureMapToPhotos()
                    }
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
                timer2.invalidate()
                
                /// initialize and start timer 2
                firetimer3()
                
                // TODO: convert the images to 2D and store locally? make a function to when the ar session ends, the images get deleted and eveyrhting resets?
            }
        
        }
        facePosition = CheckFaceHelper.shared.checkOrientationOfFace(transformMatrix: faceAnchorTransform)
        // variable to say if the face is not normal. if this variable changes, _____
        // doesn't go back to normal after 5 seconds
        
        faceOrientation = CheckFaceHelper.shared.checkPositionOfFace(transformMatrix: faceAnchorTransform)
        
        
        
        
        /// this is for the face UV unwrapping. unsure if scnfacegeometry is needed
        scnFaceGeometry.update(from: faceAnchor.geometry)
        faceUvGenerator.update(frame: frame, scene: self.sceneView.scene, headNode: node, geometry: scnFaceGeometry)
    }
    
}
