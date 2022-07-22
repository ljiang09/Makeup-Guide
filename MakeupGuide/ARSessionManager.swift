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
    let soundHelper = SoundHelper.shared
    
    @Published var isButtonShowing: Bool            // represents the button on the ContentView to get a second batch of images
    @Published var isNeckImageShowing: Bool
    @Published var isCheckImageShowing: Bool
    @Published var generatingFaceTextures2: Bool        // indicates the user wants to generate the second set of textures
    
    var faceAnchorTransform: [[Float]] = [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
    var faceImagesCollected: [Bool] = [false, false, false, false, false, false]   /// 0-2 are for first set, 3-5 for last set
    
    var facePosition: String = "blank"
    var faceOrientation: String = "blank"
    
    /// initialize timers without starting them yet
    var timer2: Timer! = nil        // for the beginning "rotate head left and right" section. Repeats every 8 seconds
    var timer3: Timer! = nil        // for checking the face position. Repeats every 3 seconds
    
    var timer4: Timer! = nil        // for collecting AR analytics every 0.5 seconds rather than every frame (120 fps)
    var timer5: Timer! = nil        // for sending analytics to firebase every 10 seconds
    
    @ObservedObject var sessionData = LogSessionData.shared
    
    var collectingData: Bool = false        // toggled by timer and collection in delegate. spaces out analytic collection so it's not every frame
    
    /// for the first set of UV textures, when the app first opens
    var headOnImgDirectory1: URL!
    var rotatedLeftImgDirectory1: URL!
    var rotatedRightImgDirectory1: URL!
    /// for the second set of UV textures, when the user clicks the "check makeup" button
    var headOnImgDirectory2: URL!
    var rotatedLeftImgDirectory2: URL!
    var rotatedRightImgDirectory2: URL!
    
    /// toggled every time a set of intro text
    @Published var isIntroTextShowing: Bool = true
    var introText: String = ""
    
    private override init() {
        isButtonShowing = false
        isNeckImageShowing = false
        isCheckImageShowing = false
        generatingFaceTextures2 = false
        
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
        
        
        appIntroduction()
        
    }
    
    /// runs voiceovers at the beginning to get the user acquainted with the app
    func appIntroduction() {
        introText = """
                   This app uses the front facing camera to check your makeup. \
                   For the app to work properly, make sure you don't have makeup \
                   on when you first open the app. \
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
        
        self.soundHelper.announce(announcement: introText)
    }
    
    func interruptVoiceover() {
        self.soundHelper.synthesizer.stopSpeaking(at: .immediate)
    }
    
    /// continually checks face until repositioned. Once it is, run the next phase of face rotation/snapshot gathering
    func runAtBeginning2() {
        self.soundHelper.announce(announcement: "This app uses the front facing camera. Follow the voiceover prompts. Hold or prop up your phone at arms length for best results.")
        
        self.fireTimer4()
        self.fireTimer5()
        
        self.checkFaceUntilRepositioned(completion: {
            self.soundHelper.playSound(soundName: "SuccessSound", dotExt: "wav")
            // TODO: run voiceover saying "face is centered"
            
            self.isCheckImageShowing = true
            /// if the user successfully positions their face (which is when this completion runs), state the instructions after 0.8 s for the user to rotate their head around and such
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.isCheckImageShowing = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.isNeckImageShowing = true
                    self.soundHelper.announce(announcement: self.soundHelper.rotateHeadInstructions)
                    
                    /// start the 2nd timer, which reminds the user every 8 seconds to rotate their head
                    self.firetimer2()
                }
            }
        })
    }
    
    /// this function is intended to run at the beginning of the app lifecycle
    /// it is also optionally called whenever the user's face is continually not centered
    ///
    /// it continually checks the face position until the face is centered and then runs the closure
    func checkFaceUntilRepositioned(completion: @escaping () -> Void) {
//        print("Timer 1 fired!")
        let timer1: Timer = Timer(fire: Date(), interval: 3.0, repeats: true, block: { timer1 in
            // TODO: change timer value (or add another timer) to check face centered more often than every 3 seconds
            if (self.facePosition == "Face is centered") {
                timer1.invalidate()
                completion()
            } else {
                self.soundHelper.announce(announcement: "please position your face in the screen")
            }
            
            if (self.facePosition != "blank") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    self.soundHelper.announce(announcement: self.facePosition)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.soundHelper.announce(announcement: self.faceOrientation)
                    }
                }
            }
//            else {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
//                    self.soundHelper.announce(announcement: "please position your face in the screen")
//                }
//            }
        })
        timer1.tolerance = 0.2
        RunLoop.current.add(timer1, forMode: .default)
    }
    
    
    
    /// this is fired when the user first correctly positions themself in the screen. every 8 seconds it reminds the user to rotate their head
    func firetimer2() {
        timer2 = Timer(fire: Date(), interval: 8.0, repeats: true, block: { _ in
            self.ontimer2Reset()
        })
        timer2.tolerance = 0.4
        
        RunLoop.current.add(timer2, forMode: .default)
//        print("Timer 2 fired!")
    }
    
    /// this is fired after the initial 3 UV images are collected.
    func firetimer3() {
        timer3 = Timer(fire: Date(), interval: 3.0, repeats: true, block: { _ in
            self.ontimer3Reset()
        })
        timer3.tolerance = 0.1
        
        RunLoop.current.add(timer3, forMode: .default)
//        print("Timer 3 fired!")
    }
    
    func fireTimer4() {
//        print("timer 4 fired")
        timer4 = Timer(fire: Date(), interval: 0.5, repeats: true, block: { _ in
            self.collectingData = true
        })
        timer4.tolerance = 0.05
        
        RunLoop.current.add(timer4, forMode: .default)
    }
    
    func fireTimer5() {
        print("timer 5 fired")
        var counter: Int = 0
        timer5 = Timer(fire: Date(), interval: 10, repeats: true, block: { _ in
            /// don't send data right when the app starts - it'll be blank
            if (counter != 0) {
                FirebaseHelpers.uploadSessionLog(int: counter)
//                print("uploded to firebase")
            }
            counter += 1
            self.sessionData.clearLogVariables()
        })
        timer5.tolerance = 1.0
        
        RunLoop.current.add(timer5, forMode: .default)
    }
    
    func ontimer2Reset() {
        // future iteration: say specifically what the probelm is. lighting, user needs to rotate a bit further, too far from screen, etc.
        /// remind the user to position their head in the screen
        self.soundHelper.announce(announcement: self.soundHelper.rotateHeadInstructions)
        
        /// state user face and orientation if the face is in the screen
        if (facePosition != "blank") {
            // TODO: change this to use a delegate to determine when the speech has ended, rather than hard coding time values https://stackoverflow.com/questions/37538131/avspeechsynthesizer-detect-when-the-speech-is-finished
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.soundHelper.announce(announcement: self.facePosition)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.soundHelper.announce(announcement: self.faceOrientation)
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.soundHelper.announce(announcement: "please position your face in the screen")
            }
        }
    }
    
    func ontimer3Reset() {
        /// check the face orientation and speak face is rotated and such
        if facePosition != "blank" {
            self.soundHelper.announce(announcement: facePosition)
        } else if faceOrientation != "blank" {
            self.soundHelper.announce(announcement: faceOrientation)
        }
    }
    
    
    /// this is called to save the first batch of textures, right when the app is opened
    private func saveTextures1() {
        collectFaceImage(whichImage: 0, expectedImage: "blank", fileName: "HeadOn1")
        collectFaceImage(whichImage: 1, expectedImage: CheckFaceHelper.shared.rotatedLeft, fileName: "RotatedLeft1")
        collectFaceImage(whichImage: 2, expectedImage: CheckFaceHelper.shared.rotatedRight, fileName: "RotatedRight1")
    }
    
    /// this fxn is called once per button click
    public func setGeneratingFaceTextures2(setTo: Bool) {
        generatingFaceTextures2 = setTo
        
        /// start repeating reminders to remind the user to rotate their head
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.isNeckImageShowing = true
            self.soundHelper.announce(announcement: self.soundHelper.rotateHeadInstructions)
            self.firetimer2()
        }
        
        
        /// create a clean slate (as if the button had never been clicked before). reset the face images collected, delete the files that were written to the points
        faceImagesCollected[3] = false
        faceImagesCollected[4] = false
        faceImagesCollected[5] = false
        
        if (headOnImgDirectory2 != nil) {
            do {
                try FileManager.default.removeItem(at: headOnImgDirectory2)
                print("deleted Head On 2 image")
            } catch {
                print("Could not clear temp folder: \(error)")
            }
        }
        if (rotatedLeftImgDirectory2 != nil) {
            do {
                try FileManager.default.removeItem(at: rotatedLeftImgDirectory2)
                print("deleted rotated left 2 image")
            } catch {
                print("Could not clear temp folder: \(error)")
            }
        }
        if (rotatedRightImgDirectory2 != nil) {
            do {
                try FileManager.default.removeItem(at: rotatedRightImgDirectory2)
                print("deleted rotated right 2 image")
            } catch {
                print("Could not clear temp folder: \(error)")
            }
        }
    }
    
    /// this is called every frame to save the second batch of textures, when the user clicks the button
    private func saveTextures2() {
        // TODO: fix the CheckFaceHelper file to show whether the face is head on, rather than whether it just hasn't been set yet. basically the goal is for the following `if` statement to not `== "blank"`
        // TODO: check to make sure the snapshots are actually good
        
        collectFaceImage(whichImage: 3, expectedImage: "blank", fileName: "HeadOn2")
        collectFaceImage(whichImage: 4, expectedImage: CheckFaceHelper.shared.rotatedLeft, fileName: "RotatedLeft2")
        collectFaceImage(whichImage: 5, expectedImage: CheckFaceHelper.shared.rotatedRight, fileName: "RotatedRight2")
    }
    
    
    /// collects 1 texture. helper function for saveTextures1 and saveTextures2
    private func collectFaceImage(whichImage: Int, expectedImage: String, fileName: String) {
        if (!faceImagesCollected[whichImage]) {
            if (CheckFaceHelper.shared.checkOrientationOfFace(transformMatrix: faceAnchorTransform) == expectedImage) {
                faceImagesCollected[whichImage] = true
                
                /// need to have a slight delay so the very first image collected isn't blank. Allow a few frames to go through first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    self.exportTextureMap(fileName: fileName)
                }
            }
        }
    }
    
    
    // MARK: Export to documents folder with name `fileName`
    /// fileName is the name you want to reference the file with, and the name to which it is saved on the UserDefaults
    private func exportTextureMap(fileName: String) {
        if let uiImage: UIImage = textureToImage(faceUvGenerator.texture) {
            
            // access documents directory
            let documents: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let url: URL = documents.appendingPathComponent(fileName)
            
            // save the image in the documents directory
            if let data: Data = uiImage.pngData() {
                do {
                    try data.write(to: url)
                    switch (fileName) {
                    case "HeadOn1":
                        headOnImgDirectory1 = url; break;
                    case "RotatedLeft1":
                        rotatedLeftImgDirectory1 = url; break;
                    case "RotatedRight1":
                        rotatedRightImgDirectory1 = url; break;
                    case "HeadOn2":
                        headOnImgDirectory2 = url; break;
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
        let x = GeneralHelpers.changeCoordinates(currentFaceTransform: faceAnchor.transform, frame: sceneView.session.currentFrame!)
        faceAnchorTransform = [[x[0][0], x[0][1], x[0][2], x[0][3]],     // column 0
                               [x[1][0], x[1][1], x[1][2], x[1][3]],
                               [x[2][0], x[2][1], x[2][2], x[2][3]],
                               [x[3][0], x[3][1], x[3][2], x[3][3]]]
        
        
        
        
        
        /// every frame, check if we have successfully collected the images. If not, try to collect them
        if (!faceImagesCollected[0] || !faceImagesCollected[1] || !faceImagesCollected[2]) {
            
            saveTextures1()
            
            /// Finish collecting images. this runs once, right when the images just finished all getting collected
            if (faceImagesCollected[0] && faceImagesCollected[1] && faceImagesCollected[2]) {
                self.soundHelper.playSound(soundName: "SuccessSound", dotExt: "wav")
                
                /// hide the instructional image
                DispatchQueue.main.async {
                    self.isNeckImageShowing = false
                    self.isButtonShowing = true
                }
                if (timer2 != nil) {
                    timer2.invalidate()
                    timer2 = nil
                }
                firetimer3()
            }
        }
        
        
        /// for when the user clicks the button
        if ((generatingFaceTextures2) && (!faceImagesCollected[3] || !faceImagesCollected[4] || !faceImagesCollected[5])) {
            
            saveTextures2()
            
            /// Finish collecting images. this runs once, right when the images just finished all getting collected
            if (faceImagesCollected[3] && faceImagesCollected[4] && faceImagesCollected[5]) {
                self.soundHelper.playSound(soundName: "SuccessSound", dotExt: "wav")
                
                /// hide the instructional image
                DispatchQueue.main.async {
                    self.isNeckImageShowing = false
                    self.generatingFaceTextures2 = false
                }
                timer2.invalidate()
                firetimer3()
            }
        }
        
        
        
        
        
        
        // variable to say if the face is not normal. if this variable changes, _____
        // doesn't go back to normal after 5 seconds
        
        facePosition = CheckFaceHelper.shared.checkPositionOfFace(transformMatrix: faceAnchorTransform)
        faceOrientation = CheckFaceHelper.shared.checkOrientationOfFace(transformMatrix: faceAnchorTransform)
        
        
        /// this is for the face UV unwrapping. unsure if scnfacegeometry is needed
        scnFaceGeometry.update(from: faceAnchor.geometry)
        faceUvGenerator.update(frame: frame, scene: self.sceneView.scene, headNode: node, geometry: scnFaceGeometry)
        
        // collect data to send to firebase, but only every 0.5 seconds (120 times per second is too much lmao)
        if (collectingData) {
            sessionData.log(faceGeometry: faceAnchor.geometry)
            
            // TODO: this one can be outside of the timer,as it doesn't have a shit ton of data every time. idk
            sessionData.log(transform: faceAnchorTransform, position: facePosition, orientation: faceOrientation)
            
            collectingData = false
        }
    }
    
}
