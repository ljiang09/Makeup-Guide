//
//  SessionData.swift
//  MakeupGuide
//
//  Created by Lily Jiang on 7/11/22.
//

import ARKit


class LogSessionData: ObservableObject {
    static var shared: LogSessionData = LogSessionData()
    
    // time, face geometry
    var faceGeometries: [(Double, ARFaceGeometry)] = []
    
    // time, transform matrix in phone coords, position declaration, orientation declaration
    var facePosAndOrient: [(Double, [[Float]], String, String)] = []
    
    // time, voiceover content
    var voiceovers: [(Double, String)] = []
    
    // time, button name
    var buttonsClicked: [(Double, String)] = []
    
    var imageCollection: [(Double, String)] = []
    
    
    /// for face geometry
    func log(faceGeometry: ARFaceGeometry) {
        faceGeometries.append((Date().timeIntervalSince1970, faceGeometry))
    }
    
    /// for face position and orientation
    func log(transform: [[Float]], position: String, orientation: String) {
        facePosAndOrient.append((Date().timeIntervalSince1970, transform, position, orientation))
    }
    
    /// for voiceover
    func log(voiceOver: String) {
        voiceovers.append((Date().timeIntervalSince1970, voiceOver))
    }
    
    /// for button press
    func log(whichButton: String) {
        buttonsClicked.append((Date().timeIntervalSince1970, whichButton))
    }
    
    func log(image: String) {
        imageCollection.append((Date().timeIntervalSince1970, image))
    }
}
