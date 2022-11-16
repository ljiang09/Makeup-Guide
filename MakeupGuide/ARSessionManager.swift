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
    static var shared: ARSessionManager = ARSessionManager()
    
    let sceneView = ARSCNView(frame: .zero)
    
    let soundHelper = SoundHelper.shared
    @ObservedObject var sessionData = LogSessionData.shared
    
    // variables for UV unwrapping
    private var faceUvGenerator: FaceTextureGenerator!
    private var scnFaceGeometry: ARSCNFaceGeometry!
    private let faceTextureSize = 1024 //px
    
    // variables for controlling the UI
    @Published var isCheckMakeupButtonShowing: Bool     // represents the button on the ContentView to get a second batch of images
    @Published var isCheckImageShowing: Bool
    @Published var generatingFaceTextures2: Bool        // indicates the user wants to generate the second set of textures
    @Published var isTextShowing: Bool = false          // toggled every time voiceover text should be be displayed on the screen
    @Published var isSkipButtonShowing1: Bool = false
    @Published var isSkipButtonShowing2: Bool = false
    
    var faceTransform: [[Float]] = [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]    // update face anchor transform when the session is collecting face info
    
    // fill this out as you collect the images
    var faceImages: [FaceOrientations: UIImage] = [:]  // slightly left, left, slightly right, right, center
    
    // change tehse variables to tell the delegate renderer function to do stuff
    var checkingFaceCentered: Bool = false
    var imageBeingCollected: FaceOrientations? = nil    // represents which image the ar session should be trying to capture
    
    
    private override init() {
        isCheckMakeupButtonShowing = false
        isCheckImageShowing = false
        generatingFaceTextures2 = false
        super.init()
        
        sceneView.session.run(ARFaceTrackingConfiguration())
        sceneView.delegate = self
        
        self.scnFaceGeometry = ARSCNFaceGeometry(device: self.sceneView.device!, fillMesh: true)
        
        self.faceUvGenerator = FaceTextureGenerator(
            device: self.sceneView.device!,
            library: self.sceneView.device!.makeDefaultLibrary()!,      // this compiles all metal files into one library
            viewportSize: UIScreen.main.bounds.size,
            face: self.scnFaceGeometry,
            textureSize: faceTextureSize)
        
        appIntroduction()
    }
    
    
    /// runs voiceovers at the beginning to get the user acquainted with the app
    func appIntroduction() {
        print("running introduction")
        
        let introText = """
                        Welcome to the Makeup Assist app!
                        This app uses the front facing camera to check your makeup. \
                        It will be useful to have your volume turned up as many \
                        instructions in the app are announced through voiceover. \
                        For the app to work properly, make sure you don't have makeup \
                        on when you first open the app.
                        First, you'll be guided to center your face in the screen. \
                        When you're centered, a success sound will play and you'll go \
                        into the next section of the app where three images will be taken \
                        of your face with no makeup on. \
                        Once those images are successfully taken, a success sound will \
                        play and you can then apply makeup. When you're done applying \
                        makeup, press the button that says "Check your makeup", located \
                        at the bottom of the screen. It will prompt you to gather another \
                        set of face images. \
                        When you're done listening to this, press the "Done" button at the \
                        bottom of the screen.
                        """
        
        isTextShowing = true
        isSkipButtonShowing1 = true
        
        self.soundHelper.latestAnnouncement = introText  // TODO: refactor the announce() function to take in a bool stating whether it should be considered the latest announcement (instead of this bs)
        self.soundHelper.announce(announcement: introText) {
//            self.appIntro2()   // this is being controlled by the done button
        }
    }
    
    /// continually checks face until repositioned. Once it is, run the next phase of face rotation/snapshot gathering
    func appIntro2() {
        print("running intro 2")
        
        let announcement = """
                           Follow the voiceover prompts. \
                           Point the front facing camera towards your face. Hold or prop \
                           up your phone at about arms length for best results. Now, we \
                           will take pictures of your face at different angles to represent \
                           what your face looks like without makeup on. This will later be \
                           compared to your face after you apply makeup, to check where the \
                           makeup is on your face. Start by moving your face around until \
                           it is centered in the screen.
                           """
        self.soundHelper.latestAnnouncement = announcement
        isTextShowing = true
        isSkipButtonShowing2 = true
        
        
        // have to delay it a bit so the announcement manager can catch up. Otherwise, it'll think the completion is reached when the first announcment is done
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // announce the instructions. On completion, start flow of centering the user's face in the screen
            self.soundHelper.announce(announcement: announcement) {
                self.isTextShowing = false
                self.centerFaceFlow()
                
                // TODO: start timer to send analytics to firebase every 10 seconds
            }
        }
    }
    
    
    
    func centerFaceFlow() {
        // NOTES: possible improvements to be made
        // possibly also tell them how far away they are from the screen, and encourage them to move their phone forwards/backwards
        
        print("centering face")
        
        // 1. center face with immediate feedback
        self.checkFaceUntilRepositioned(whichOrientation: FaceOrientations.center) {
            self.soundHelper.playSound(soundName: "SuccessSound", dotExt: "wav")
            self.isCheckImageShowing = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.isCheckImageShowing = false
                
                self.soundHelper.announce(announcement: "Face is now centered.") {
                    // 2. capture images in order
                    self.collectImageStart(whichImage: FaceOrientations.slightlyLeft) {
                        print("collected slightly left")
                        self.collectImageStart(whichImage: FaceOrientations.left) {
                            print("collected left")
                            self.collectImageStart(whichImage: FaceOrientations.slightlyRight) {
                                print("collected slightly right")
                                self.collectImageStart(whichImage: FaceOrientations.right) {
                                    print("collected right. Done")
                                    // TODO: fill this flow out
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    /// instructs the user to turn their head to a specified orientation, then waits 1 second before taking the picture
    func collectImageStart(whichImage: FaceOrientations, completion: @escaping ()->()) {
        print("collecting image \(whichImage.rawValue)")
        
        // state the instructions
        // TODO: check if this latest announcement is shown on the screen
        var announcement = "Turn your head \(whichImage.rawValue) until you hear the success sound. Then, hold your head in place."
        self.soundHelper.latestAnnouncement = announcement
        self.soundHelper.announce(announcement: announcement) {
            
            // check face until slightly left. in the completion, run success sound and such
            self.checkFaceUntilRepositioned(whichOrientation: whichImage) {
                self.soundHelper.playSound(soundName: "SuccessSound", dotExt: "wav")
                self.isCheckImageShowing = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.isCheckImageShowing = false
                    
                    announcement = "Hold your head in place to collect the image."
                    self.soundHelper.latestAnnouncement = announcement
                    self.soundHelper.announce(announcement: announcement) {
                        // change the optional variable to indicate that the renderer should look for the specified position
                        self.imageBeingCollected = whichImage
                        
                        // NOTE: Eventually you can check if the user has successfully held their face still for that long (probably w/ a timer)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            // after 1 second, capture the image and associated data
                            self.collectTexture(whichImage: whichImage)
                            self.collect2DImage(whichImage: whichImage)
                            self.collectImageData(whichImage: whichImage)
                            
                            self.imageBeingCollected = nil
                            
                            completion()
                        }
                    }
                }
            }
        }
    }
    
    
    /// given the face transform and texture, extracts and saves the UV texture
    /// `whichImage` corresponds to `FaceOrientations`
    func collectTexture(whichImage: FaceOrientations) {
        if let uiImage: UIImage = textureToImage(faceUvGenerator.texture) {
            
            // Supposedly, since the user's face is centered before the first image is being taken, this should make the images be good.....
//            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            
            // save the image in the class variable, accessible through the shared singleton
            self.faceImages[whichImage] = uiImage
            
            let fileName: String = whichImage.rawValue
            
            /// send the image to Firebase to be stored
            FirebaseHelpers.shared.uploadTester(imageData: uiImage.pngData()!, fileName: fileName)
//            FirebaseHelpers.upload(imageData: uiImage.pngData()!, fileName: fileName)

            sessionData.log(image: fileName)
        } else {
            print("export failed")
        }
    }
    
    
    /// collects image as directly seen in the screen
    func collect2DImage(whichImage: FaceOrientations) {
        // collects image as directly seen in the screen
        guard let imageBuffer = sceneView.session.currentFrame?.capturedImage else {
            print("error with getting camera image")
            return
        }

        // upload the image buffer to firebase
        if let data = imageBuffer.toUIImage()?.pngData() {
            FirebaseHelpers.shared.uploadTester(imageData: data, fileName: "\(whichImage.rawValue)ImageBuffer")
//            FirebaseHelpers.upload(imageData: data, fileName: "\(whichImage.rawValue)ImageBuffer")
        }
    }
    
    
    /// collects and uploads the data into firebase
    func collectImageData(whichImage: FaceOrientations) {
        // Upload a data file with all the camera information
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform,
              let cameraIntrinsics = sceneView.session.currentFrame?.camera.intrinsics else {
            print("error with getting transform data")
            return
        }
        
        print("")
        
        FirebaseHelpers.shared.uploadTester(fileName: "\(whichImage.rawValue)CameraInfo", cameraTransform: cameraTransform, cameraIntrinsics: cameraIntrinsics)
//        FirebaseHelpers.upload(fileName: "\(whichImage.rawValue)CameraInfo", cameraTransform: cameraTransform, cameraIntrinsics: cameraIntrinsics)
    }
    
    
    /// runs a short timer where in every loop, the desired face position is checked against the current face position
    /// This current face position is updated every frame by the renderer delegate function
    func checkFaceUntilRepositioned(whichOrientation: FaceOrientations, completion: @escaping () -> Void) {
        
        print("checking face until repositioned")
        
        // tell the renderer to start checking the face transforms
        checkingFaceCentered = true
        
        let faceCheckTimer = Timer(fire: Date(), interval: 0.25, repeats: true) { faceCheckTimer in
            // continually compare the updated face position to the desired face position
            
            // MARK: uncomment this if you want to get data for the python analysis
//            print(self.faceTransform)
            
            if whichOrientation == CheckFaceHelper.shared.orientation {
                faceCheckTimer.invalidate()
                completion()
            }
        }
        faceCheckTimer.tolerance = 0.05
        RunLoop.current.add(faceCheckTimer, forMode: .default)
        
        
        
//        if (self.facePosition != "Face is centered") {
//            announcement = "Please center your face in the screen. "
//            if (self.facePosition != "blank") {
//                announcement = announcement + self.facePosition
//            }
//
//            /// for some reason the announcements will not keep playing if i use the shared instance, so i'm just making a new instance each time and it seems to announce it each time like intended
//            self.soundHelper.announce(announcement: announcement)
//            self.soundHelper.latestAnnouncement = announcement
//        } else if (self.faceOrientation != CheckFaceHelper.shared.headOn) {
//            announcement = "Please turn your face towards the camera. " + self.faceOrientation
//            self.soundHelper.announce(announcement: announcement)
//            self.soundHelper.latestAnnouncement = announcement
//        }
    }
}



// MARK: - Sceneview delegate
extension ARSessionManager: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        /// replaced the old code that made a mesh on your face, with the code that was in the HeadShot renderer()
        guard anchor is ARFaceAnchor else {
            return nil
        }
        /// this is for the face UV unwrapping. Unsure if its needed
        let node = SCNNode(geometry: scnFaceGeometry)
        
        // note that this doesn't actually generate an overlay since it's the first frame. if you want to see the overlay of your UV textured face, pace this line in the other delegate function
        scnFaceGeometry.firstMaterial?.diffuse.contents = textureToImage(faceUvGenerator.texture)
        
        return node
    }
    
    
    /// this makes the mesh mask move as you blink, open mouth, etc.
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        //scnFaceGeometry.firstMaterial?.diffuse.contents = textureToImage(faceUvGenerator.texture)
        
        /// check to make sure the face anchor and geometry being updated are the correct types (`ARFaceAnchor` and `ARSCNFaceGeometry`)
        guard let faceAnchor = anchor as? ARFaceAnchor,
              let frame = sceneView.session.currentFrame,
              let faceGeometry = node.geometry as? ARSCNFaceGeometry else { return }
        
        /// Update `ARSCNFaceGeometry` using the `ARFaceGeometry` corresponding to the `ARFaceAnchor`
        faceGeometry.update(from: faceAnchor.geometry)
        
        
        
        // check the face positioning and update the variable
        if self.checkingFaceCentered {
            // change to the camera's coordinate system
            let x = GeneralHelpers.changeCoordinates(currentFaceTransform: faceAnchor.transform, frame: sceneView.session.currentFrame!)
            faceTransform = [[x[0][0], x[0][1], x[0][2], x[0][3]],     // column 0
                             [x[1][0], x[1][1], x[1][2], x[1][3]],
                             [x[2][0], x[2][1], x[2][2], x[2][3]],
                             [x[3][0], x[3][1], x[3][2], x[3][3]]]
            
            
            
            CheckFaceHelper.shared.getOrientation(faceTransform: faceTransform)
            
            
        }
        
        
        // collect images when reasonable
        if self.imageBeingCollected != nil {
            // change the coordinate system to be the camera (mathematically)
            let x = GeneralHelpers.changeCoordinates(currentFaceTransform: faceAnchor.transform, frame: sceneView.session.currentFrame!)
            faceTransform = [[x[0][0], x[0][1], x[0][2], x[0][3]],     // column 0
                             [x[1][0], x[1][1], x[1][2], x[1][3]],
                             [x[2][0], x[2][1], x[2][2], x[2][3]],
                             [x[3][0], x[3][1], x[3][2], x[3][3]]]
            
            
            // TODO: possible way to go about this: constantly read in the transformt data and have a function that returns a specific string corresponding to some of those values. If that value matches with self.imageBeingCollected, take a snapshot of it (in this delegate!)
            
        }
        
        
        /// this is for the face UV unwrapping. unsure if scnfacegeometry is needed
        scnFaceGeometry.update(from: faceAnchor.geometry)
        
        faceUvGenerator.update(frame: frame, scene: self.sceneView.scene, headNode: node, geometry: scnFaceGeometry)
        
        /// collect data to send to firebase, but only every 0.5 seconds (120 times per second is too much lmao)
//        if (collectingData) {
//            sessionData.log(faceGeometry: faceAnchor.geometry)
//
//            // TODO: this one can be outside of the timer,as it doesn't have a shit ton of data every time. idk
//            sessionData.log(transform: faceAnchorTransform, position: facePosition, orientation: faceOrientation)
//
//            collectingData = false
//        }
    }
    
}
