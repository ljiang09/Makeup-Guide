//
//  ARSessionManager.swift
//  MakeupGuide
//
//  Created by Lily Jiang on 6/14/22.
//

import SwiftUI
import SceneKit
import ARKit

class ARSessionManager: NSObject {
    let sceneView = ARSCNView(frame: .zero)
    
    static var shared: ARSessionManager = ARSessionManager()
    
    private override init() {
        super.init()
        sceneView.session.run(ARFaceTrackingConfiguration())
        sceneView.delegate = self
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
        let faceAnchorTransform: [[Float]] = [[x[0][0], x[0][1], x[0][2], x[0][3]],
                                              [x[1][0], x[1][1], x[1][2], x[1][3]],
                                              [x[2][0], x[2][1], x[2][2], x[2][3]],
                                              [x[3][0], x[3][1], x[3][2], x[3][3]]]
        
        
        
        
        
//
//        /// every frame, check if we have successfully collected the images. If not, try to collect them
//        if (faceImages[0] == nil || faceImages[1] == nil || faceImages[2] == nil) {
//            DispatchQueue.main.async {
//                self.neckRotationImage.isHidden = false
//            }
//
//
//            if (faceImages[0] == nil) {
//                if (CheckFaceHelper.checkOrientationOfFace(transformMatrix: faceAnchorTransform) == "") {
//                    faceImages[0] = sceneView.snapshot()
//                    print("head on image collected")
////                    displayFaceImages.image = faceImages[0]
//                }
//            }
//            if (faceImages[1] == nil) {
//                if (CheckFaceHelper.checkOrientationOfFace(transformMatrix: faceAnchorTransform) == "Rotated Left") {
//                    faceImages[1] = sceneView.snapshot()
//                    print("rotated left image collected")
////                    displayFaceImages.image = faceImages[1]
//                }
//            }
//            if (faceImages[2] == nil) {
//                if (CheckFaceHelper.checkOrientationOfFace(transformMatrix: faceAnchorTransform) == "Rotated Right") {
//                    faceImages[2] = sceneView.snapshot()
//                    print("rotated right image collected")
////                    displayFaceImages.image = faceImages[2]
//                }
//            }
//        }
//        else {
//            DispatchQueue.main.async {
//                self.neckRotationImage.isHidden = true
//            }
//
//            /// check orientation of face
//            print(CheckFaceHelper.checkOrientationOfFace(transformMatrix: faceAnchorTransform))
//            // variable to say if the face is not normal. if this variable changes, _____
//            // doesn't go back to normal after 5 seconds
//
//            /// check position of face
//            print(CheckFaceHelper.checkPositionOfFace(transformMatrix: faceAnchorTransform))
//        }
        // TODO: check to make sure the snapshots are actually good
        
    }
    
}
