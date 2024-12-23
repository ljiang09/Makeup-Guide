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
    let sceneView = ARSCNView(frame: .zero)
    static var shared: ARSessionManager = ARSessionManager()
    let soundHelper = SoundHelper.shared
    @ObservedObject var sessionData = LogSessionData.shared
    
    /// variables for UV unwrapping
    private var faceUvGenerator: FaceTextureGenerator!
    private var scnFaceGeometry: ARSCNFaceGeometry!
    private let faceTextureSize = 1024 //px
    
    @Published var isCheckMakeupButtonShowing: Bool     // represents the button on the ContentView to get a second batch of images
    @Published var isCheckImageShowing: Bool
    @Published var generatingFaceTextures2: Bool        // indicates the user wants to generate the second set of textures
    @Published var isTextShowing: Bool = false          // toggled every time a long voiceover is read and needs to be displayed as text on the screen
    
    var faceAnchorTransform: [[Float]] = [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
    var faceImagesCollected: [Bool] = [false, false, false, false, false, false, false, false]   /// 0-3 are for first set, 4-7 for last set
    
    var facePosition: String = "blank"
    var faceOrientation: String = "blank"
    
    /// initialize timers without starting them yet
    var timer2: Timer! = nil        // for the beginning "rotate head left and right" section. Repeats every 8 seconds
    var timer4: Timer! = nil        // for collecting AR analytics every 0.5 seconds rather than every frame (120 fps)
    var timer5: Timer! = nil        // for sending analytics to firebase every 10 seconds
    
    var collectingData: Bool = false        // toggled by timer and collection in delegate. spaces out analytic collection so it's not every frame
    
    /// for the first set of UV textures, when the app first opens
    var slightLeftImgDirectory1: URL!
    var slightRightImgDirectory1: URL!
    var rotatedLeftImgDirectory1: URL!
    var rotatedRightImgDirectory1: URL!
    /// for the second set of UV textures, when the user clicks the "check makeup" button
    var slightLeftImgDirectory2: URL!
    var slightRightImgDirectory2: URL!
    var rotatedLeftImgDirectory2: URL!
    var rotatedRightImgDirectory2: URL!
    
    /// this prevents the face textures from being collected during the intro text and the other beginning sections of the app
    var readyToCollectFaceImages: Bool = false
    
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
        
        self.soundHelper.latestAnnouncement = introText // TODO: refactor the announce() function to take in a bool stating whether it should be considered the latest announcement (instead of this bs)
        self.soundHelper.announce(announcement: introText) {
            self.isTextShowing = false
            self.runAtBeginning2()
        }
    }
    
    /// this should be used mainly to stop the face position/orientation voiceovers because they rely on the shared instance of the soundhelpers class
    func interruptVoiceover() {
        self.soundHelper.synthesizer.stopSpeaking(at: .immediate)
        // TODO: clear the queue here within the function rather than just calling this fxn twice when needed
        
        DispatchQueue.main.async {
            self.isTextShowing = false
        }
    }
    
    /// continually checks face until repositioned. Once it is, run the next phase of face rotation/snapshot gathering
    func runAtBeginning2() {
        isTextShowing = true
        
        let announcement: String = "Follow the voiceover prompts. Point the front facing camera towards your face. Hold or prop up your phone at about arms length for best results. Now, we will take pictures of your face facing forward, turned left, and turned right to represent what your face looks like without makeup on. This will later be compared to your face after you apply makeup, to check where you have applied makeup. Start by moving your face around until it is centered in the screen."
        self.soundHelper.latestAnnouncement = announcement
        self.soundHelper.announce(announcement: announcement) {
            self.isTextShowing = false
            self.fireTimer4()
            self.fireTimer5()
            
            self.checkFaceUntilRepositioned(completion: {
                self.soundHelper.playSound(soundName: "SuccessSound", dotExt: "wav")
                self.isCheckImageShowing = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.soundHelper.announce(announcement: "Face is now centered.")
                    
                    /// if the user successfully positions their face (which is when this completion runs), state the instructions after 0.8 s for the user to rotate their head around and such
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.isCheckImageShowing = false
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                        self.soundHelper.announce(announcement: self.soundHelper.rotateHeadInstructions)
                        self.soundHelper.latestAnnouncement = self.soundHelper.rotateHeadInstructions
                        // TODO: check if this latest announcement is shown on the screen
                        
                        /// start the 2nd timer, which reminds the user every 8 seconds to rotate their head
                        self.firetimer2()
                        
                        print("face image collections should be happening now")
                        self.readyToCollectFaceImages = true
                    }
                }
            })
        }
        
    }
    
    /// this is called when the "Check your Makeup" button is clicked
    public func setGeneratingFaceTextures2() {
        
        interruptVoiceover()
        
        generatingFaceTextures2 = true
        
        /// create a clean slate (as if the button had never been clicked before). reset the face images collected, delete the files that were written to the points
        self.faceImagesCollected[4] = false
        self.faceImagesCollected[5] = false
        self.faceImagesCollected[6] = false
        self.faceImagesCollected[7] = false
        
        let possibleDirectories = [slightLeftImgDirectory2,
                                   slightRightImgDirectory2,
                                   rotatedLeftImgDirectory2,
                                   rotatedRightImgDirectory2]
        
        for directory in possibleDirectories {
            if (directory != nil) {
                do {
                    try FileManager.default.removeItem(at: directory!)
                    print("deleted image at \(String(describing: directory))")
                } catch {
                    print("Could not clear temp folder: \(error)")
                }
            }
        }
        
        
        // TODO: for some reason this text isn't showing. the announcement voiceover works and the completion works but the text and button do not work. boo
        self.isTextShowing = false
        /// run face centering stuff again since they presumably put their phone down.
        let announcement: String = "Now that you're done applying makeup, let's take a few more images to compare to the images you took earlier without makeup on. Start by centering your face in the screen again."
        self.soundHelper.latestAnnouncement = announcement
        self.isTextShowing = true
        
        
        self.soundHelper.announce(announcement: announcement) {
            self.isTextShowing = false
            
            self.checkFaceUntilRepositioned(completion: {
                self.soundHelper.playSound(soundName: "SuccessSound", dotExt: "wav")
                self.isCheckImageShowing = true
                
//                self.generatingFaceTextures2 = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.soundHelper.announce(announcement: "Face is now centered.")
                    
                    // TODO: make these all separate instances of the class so you can run multiple nested completions
                    /// if the user successfully positions their face (which is when this completion runs), state the instructions after 0.8 s for the user to rotate their head around and such
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.isCheckImageShowing = false
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            self.soundHelper.announce(announcement: self.soundHelper.rotateHeadInstructions)
                            self.soundHelper.latestAnnouncement = self.soundHelper.rotateHeadInstructions
                            
                            /// start the 2nd timer, which reminds the user every 8 seconds to rotate their head
                            self.firetimer2()
                            
                            self.readyToCollectFaceImages = true
                        }
                    }
                }
            })
        }
    }
    
    
    /// this function is intended to run at the beginning of the app lifecycle
    /// it continually checks the face position until the face is centered and then runs the closure
    func checkFaceUntilRepositioned(completion: @escaping () -> Void) {
        var announcement: String = ""
        
        /// this timer states the user's face position every 3 seconds, and when the position is centered, it starts stating the orientation of the face
        let timer1: Timer = Timer(fire: Date(), interval: 4.0, repeats: true, block: { timer1 in
            
            /// get the user to center their face first, then orient it correctly
            if (self.facePosition != "Face is centered") {
                announcement = "Please center your face in the screen. "
                if (self.facePosition != "blank") {
                    announcement = announcement + self.facePosition
                }
                
                /// for some reason the announcements will not keep playing if i use the shared instance, so i'm just making a new instance each time and it seems to announce it each time like intended
                self.soundHelper.announce(announcement: announcement)
                self.soundHelper.latestAnnouncement = announcement
            } else if (self.faceOrientation != CheckFaceHelper.shared.headOn) {
                announcement = "Please turn your face towards the camera. " + self.faceOrientation
                self.soundHelper.announce(announcement: announcement)
                self.soundHelper.latestAnnouncement = announcement
            }
        })
        timer1.tolerance = 0.2
        RunLoop.current.add(timer1, forMode: .default)
        
        
        /// this timer checks the user's face position every 0.5 seconds based on the renderer's updates, controls when the completion handler runs (based on both position and orientation of the face)
        // TODO: change this to be a function of the renderer(), activated only by a variable
        let timer3: Timer = Timer(fire: Date(), interval: 0.5, repeats: true, block: { timer3 in

            if (self.facePosition == "Face is centered" && self.faceOrientation == CheckFaceHelper.shared.headOn) {
                /// the face is correctly positioned in the screen and now you can invalidate both timers and run the completion handler
                timer1.invalidate()
                timer3.invalidate()
                completion()
            }

        })
        timer3.tolerance = 0.05
        RunLoop.current.add(timer3, forMode: .default)
    }
    
    
    /// this is fired when the user first correctly positions themself in the screen. every 8 seconds it reminds the user to rotate their head
    func firetimer2() {
        timer2 = Timer(fire: Date(), interval: 8.0, repeats: true, block: { _ in
            self.ontimer2Reset()
        })
        timer2.tolerance = 0.4
        RunLoop.current.add(timer2, forMode: .default)
    }
    
    func ontimer2Reset() {
        // future iteration: say specifically what the probelm is. lighting, user needs to rotate a bit further, too far from screen, etc.
        /// remind the user to position their head in the screen
        self.soundHelper.announce(announcement: self.soundHelper.rotateHeadInstructions) {
            /// state user face and orientation if the face is in the screen
            // TODO: fix this to actually find the face in the screen rather than just using the last face geometry that got stored
            if (self.facePosition != "blank") {
                self.soundHelper.announce(announcement: "\(self.facePosition), \(self.faceOrientation)")
//                self.soundHelper.latestAnnouncement = self.facePosition + self.faceOrientation
            } else {
                self.soundHelper.announce(announcement: "please position your face in the screen")
                self.soundHelper.latestAnnouncement = "please position your face in the screen"
            }
        }
        self.soundHelper.latestAnnouncement = self.soundHelper.rotateHeadInstructions
    }
    
    func fireTimer4() {
        timer4 = Timer(fire: Date(), interval: 0.5, repeats: true, block: { _ in
            self.collectingData = true
        })
        timer4.tolerance = 0.05
        RunLoop.current.add(timer4, forMode: .default)
    }
    
    /// every 10 seconds, send analytics to firebase
    func fireTimer5() {
        var counter: Int = 0
        timer5 = Timer(fire: Date(), interval: 10, repeats: true, block: { _ in
            /// don't send data right when the app starts - it'll be blank
            if (counter != 0) {
                FirebaseHelpers.uploadSessionLog(int: counter)
            }
            counter += 1
            self.sessionData.clearLogVariables()
        })
        timer5.tolerance = 1.0
        RunLoop.current.add(timer5, forMode: .default)
    }
    
    
    /// this is called to save the first batch of textures, right when the app is opened
    private func saveTextures1() {
        collectFaceImage(whichImage: 0, expectedImage: CheckFaceHelper.shared.rotatedSlightLeft, fileName: "SlightLeft1")
        collectFaceImage(whichImage: 1, expectedImage: CheckFaceHelper.shared.rotatedSlightRight, fileName: "SlightRight1")
        collectFaceImage(whichImage: 2, expectedImage: CheckFaceHelper.shared.rotatedLeft, fileName: "RotatedLeft1")
        collectFaceImage(whichImage: 3, expectedImage: CheckFaceHelper.shared.rotatedRight, fileName: "RotatedRight1")
    }
    
    /// this is called every frame to save the second batch of textures, when the user clicks the button
    private func saveTextures2() {
        // TODO: check to make sure the snapshots are actually good
        collectFaceImage(whichImage: 4, expectedImage: CheckFaceHelper.shared.rotatedSlightLeft, fileName: "SlightLeft2")
        collectFaceImage(whichImage: 5, expectedImage: CheckFaceHelper.shared.rotatedSlightRight, fileName: "SlightRight2")
        collectFaceImage(whichImage: 6, expectedImage: CheckFaceHelper.shared.rotatedLeft, fileName: "RotatedLeft2")
        collectFaceImage(whichImage: 7, expectedImage: CheckFaceHelper.shared.rotatedRight, fileName: "RotatedRight2")
    }
    
    
    /// collects 1 texture. helper function for saveTextures1 and saveTextures2
    private func collectFaceImage(whichImage: Int, expectedImage: String, fileName: String) {
        if (!faceImagesCollected[whichImage]) {
            if (CheckFaceHelper.shared.checkOrientationOfFace(transformMatrix: faceAnchorTransform) == expectedImage) {
                faceImagesCollected[whichImage] = true
                print("stored image at \(fileName)")
                
                /// need to have a slight delay so the very first image collected isn't blank. Allow a few frames to go through first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    self.exportTextureMap(fileName: fileName)
                    self.exportSnapshot(fileName: "\(fileName)\(whichImage)")
                }
            }
        }
    }
    
    
    // MARK: Export to documents folder with name `fileName`
    /// fileName is the name you want to reference the file with, and the name to which it is saved on the UserDefaults
    private func exportTextureMap(fileName: String) {
        if let uiImage: UIImage = textureToImage(faceUvGenerator.texture) {
            
            // Supposedly, since the user's face is centered before the first image is being taken, this should make the images be good.....
//            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            
            // access documents directory
            let documents: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let url: URL = documents.appendingPathComponent(fileName)
            
            // save the image in the documents directory
            if let data: Data = uiImage.pngData() {
                do {
                    try data.write(to: url)
                    switch (fileName) {
                    case "SlightLeft1":
                        slightLeftImgDirectory1 = url; break;
                    case "SlightRight1":
                        slightRightImgDirectory1 = url; break;
                    case "RotatedLeft1":
                        rotatedLeftImgDirectory1 = url; break;
                    case "RotatedRight1":
                        rotatedRightImgDirectory1 = url; break;
                    case "SlightLeft2":
                        slightLeftImgDirectory2 = url; break;
                    case "SlightRight2":
                        slightRightImgDirectory2 = url; break;
                    case "RotatedLeft2":
                        rotatedLeftImgDirectory2 = url; break;
                    case "RotatedRight2":
                        rotatedRightImgDirectory2 = url; break;
                    default:
                        print("specified filename for the texture image is not valid"); break;
                    }
                } catch {
                    print("Unable to Write Image Data to Disk")
                }
                
                /// send the image to Firebase to be stored
                FirebaseHelpers.upload(imageData: data, fileName: fileName)
                
                sessionData.log(image: fileName)
            }
        } else {
            print("export failed")
        }
    }
    
    
    // MARK: send a set of regular images alongside the unwrapped textures
    /// fileName is the name you want to reference the file with, and the name to which it is saved on the UserDefaults
    private func exportSnapshot(fileName: String) {
        // keep this in so that you still have it to easily compare it
        let image = sceneView.snapshot()
        
        guard let imageBuffer = sceneView.session.currentFrame?.capturedImage,
              let cameraTransform = sceneView.session.currentFrame?.camera.transform,
              let cameraIntrinsics = sceneView.session.currentFrame?.camera.intrinsics else {
            print("error with getting camera image and transform data")
            return
        }
        
        // upload the image buffer to firebase
        if let data = imageBuffer.toUIImage()?.pngData() {
            FirebaseHelpers.upload(imageData: data, fileName: "\(fileName)ImageBuffer")
        }
        
        // upload the 2D image to firebase
        if let data: Data = image.pngData() {
            /// send the image to Firebase to be stored
            FirebaseHelpers.upload(imageData: data, fileName: fileName)
        }
        
        // Upload a data file with all the ARFaceGeometry information
        FirebaseHelpers.upload(fileName: fileName, cameraTransform: cameraTransform, cameraIntrinsics: cameraIntrinsics)
        
        // upload camera intristics, camera transforms
        
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
        
        /// change the coordinate system to be the camera (mathematically)
        let x = GeneralHelpers.changeCoordinates(currentFaceTransform: faceAnchor.transform, frame: sceneView.session.currentFrame!)
        faceAnchorTransform = [[x[0][0], x[0][1], x[0][2], x[0][3]],     // column 0
                               [x[1][0], x[1][1], x[1][2], x[1][3]],
                               [x[2][0], x[2][1], x[2][2], x[2][3]],
                               [x[3][0], x[3][1], x[3][2], x[3][3]]]
        
        
        
        
        
        /// every frame, check if we have successfully collected the images. If not, try to collect them
        if ((!faceImagesCollected[0] || !faceImagesCollected[1] || !faceImagesCollected[2] || !faceImagesCollected[3]) && readyToCollectFaceImages) {
            
            saveTextures1()
            
            /// Finish collecting images. this runs once, right when the images just finished all getting collected
            if (faceImagesCollected[0] && faceImagesCollected[1] && faceImagesCollected[2] && faceImagesCollected[3]) {
                
                self.interruptVoiceover()       /// interrupt the face position/orientation voiceovers (since they rely on the shared SoundHelper instance)
                
                self.soundHelper.playSound(soundName: "SuccessSound", dotExt: "wav")
                
                /// hide the instructional image and show the "check makeup" button + text
                DispatchQueue.main.async {
                    self.isCheckMakeupButtonShowing = true
                }
                if (timer2 != nil) {
                    timer2.invalidate()
                    timer2 = nil
                }
                
                // MARK: the problem seems to be that it gets caught up in trying to say face position and orientation from the repeating function in timer2, even though that should all be interrupted.... so hwen it tries to queue the next announcement up, there isn't room to do so since it stores only 2 at one time. but anyways having it delay for a short bit of time seems to make it work??? haven't thoroughly debugged this yet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    let announcement = "Now, apply makeup. Whenever you're done, click the button at the bottom of the screen to check your makeup."
                    
                    self.interruptVoiceover()
                    self.interruptVoiceover()
                    
                    self.soundHelper.latestAnnouncement = announcement
                    self.isTextShowing = true
                    
                    self.soundHelper.announce(announcement: announcement) {
                        self.isTextShowing = false
                    }
                }
            }
        }
        
        
        /// for when the user clicks the button
        if ((generatingFaceTextures2) && (!faceImagesCollected[4] || !faceImagesCollected[5] || !faceImagesCollected[6] || !faceImagesCollected[7])) {
            
            saveTextures2()
            
            /// Finish collecting images. this runs once immediately when the second batch of images just finished all getting collected
            if (faceImagesCollected[4] && faceImagesCollected[5] && faceImagesCollected[6] && faceImagesCollected[7]) {
                self.soundHelper.playSound(soundName: "SuccessSound", dotExt: "wav")
                
                /// hide the instructional image
                DispatchQueue.main.async {
                    self.generatingFaceTextures2 = false
                }
                
                if (timer2 != nil) {
                    timer2.invalidate()
                    timer2 = nil
                }
                
                /// announcement after the second set of face images is collected
                let announcement = "Now the app will check over your face of makeup. Note that right now, this part of the app is not implemented yet so this voiceover is just a placeholder. If you want to check your makeup again, you can click the button at the bottom of the screen."    // TODO: when you add the analysis part of the app, move the last sentence to be after the analysis (because right now this will be before the analysis happens
                self.soundHelper.latestAnnouncement = announcement
                self.soundHelper.announce(announcement: announcement) {
                    print("done")
                }
            }
        }
        
        
        
        
        
        facePosition = CheckFaceHelper.shared.checkPositionOfFace(transformMatrix: faceAnchorTransform)
        faceOrientation = CheckFaceHelper.shared.checkOrientationOfFace(transformMatrix: faceAnchorTransform)
        
        
        /// this is for the face UV unwrapping. unsure if scnfacegeometry is needed
        scnFaceGeometry.update(from: faceAnchor.geometry)
        
        faceUvGenerator.update(frame: frame, scene: self.sceneView.scene, headNode: node, geometry: scnFaceGeometry)
        
        /// collect data to send to firebase, but only every 0.5 seconds (120 times per second is too much lmao)
        if (collectingData) {
            sessionData.log(faceGeometry: faceAnchor.geometry)
            
            // TODO: this one can be outside of the timer,as it doesn't have a shit ton of data every time. idk
            sessionData.log(transform: faceAnchorTransform, position: facePosition, orientation: faceOrientation)
            
            collectingData = false
        }
    }
    
}
