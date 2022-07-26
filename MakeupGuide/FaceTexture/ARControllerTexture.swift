/*
ARControllerTexture.swift
https://github.com/mattbierner/headshot
Created by Lily Jiang on 6/24/22

This file ______
*/

import ARKit
import SceneKit
import UIKit

/// Size of the generated face texture
private let faceTextureSize = 1024 //px

/// Should the face mesh be filled in? (i.e. fill in the eye and mouth holes with geometry)
private let fillMesh = true

class ARViewController: UIViewController, ARSCNViewDelegate {
    
    private var faceUvGenerator: FaceTextureGenerator!
    private var scnFaceGeometry: ARSCNFaceGeometry!
    
    // MARK: AR View
    
    /// Primary AR view
    private var sceneView: ARSCNView!
    
    // MARK: Preview scene
    
    /// Secondary scene view that shows the captured face
    private var previewSceneView: SCNView!
    private var previewFaceNode: SCNNode!
    private var previewFaceGeometry: ARSCNFaceGeometry!
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView = ARSCNView(frame: self.view.bounds, options: nil)
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = false
        sceneView.rendersCameraGrain = true
        self.view.addSubview(sceneView)
        
        self.scnFaceGeometry = ARSCNFaceGeometry(device: self.sceneView.device!, fillMesh: fillMesh)
        
        self.faceUvGenerator = FaceTextureGenerator(
            device: self.sceneView.device!,
            library: self.sceneView.device!.makeDefaultLibrary()!,
            viewportSize: UIScreen.main.bounds.size,
            face: self.scnFaceGeometry,
            textureSize: faceTextureSize)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        resetTracking()
    }
    
    // MARK: AR
    
    private func resetTracking() {
        sceneView.session.run(ARFaceTrackingConfiguration(),
                              options: [.removeExistingAnchors,
                                        .resetTracking,
                                        .resetSceneReconstruction,
                                        .stopTrackedRaycasts])
    }
}
