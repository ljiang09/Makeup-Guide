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
    
    /// for when the image is collected (mainly looking at timestamps and order of collection here)
    func log(image: String) {
        imageCollection.append((Date().timeIntervalSince1970, image))
    }
    
//    func compileToJSON() -> [String: [String: Double]] {
//        ["faceGeometries": sessionData.faceGeometries.map({ faceGeometry in ["timestamp": faceGeometry.0, "vertices": faceGeometry.1.vertices.map({ vertex in [vertex.x, vertex.y, vertex.z ]})] } ) ]
//        // compile all the data into a dictionaty. return that
//    }
}
