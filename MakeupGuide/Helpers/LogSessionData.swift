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
    
    
    func log(faceGeometry: ARFaceGeometry) {
        faceGeometries.append((Date().timeIntervalSince1970, faceGeometry))
    }
    
    func logFacePositionOrientation(transform: [[Float]], position: String, orientation: String) {
        facePosAndOrient.append((Date().timeIntervalSince1970, transform, position, orientation))
    }
    
    func logVoiceOver(voiceOver: String) {
        voiceovers.append((Date().timeIntervalSince1970, voiceOver))
    }
    
    func logButtonPress(whichButton: String) {
        buttonsClicked.append((Date().timeIntervalSince1970, whichButton))
    }
}
