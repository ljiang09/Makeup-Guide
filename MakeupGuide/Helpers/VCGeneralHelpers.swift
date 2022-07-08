/*
GeneralHelpers.swift
MakeupGuide
Created by Lily Jiang on 6/13/22

This file holds a helper function to convert the face anchor transform matrix from world to camera coordinates.
Note that the camera axes are oriented differently. +x points down and +y points to the right.
It also holds extensions
*/

import ARKit
import SwiftUI
import SceneKit


class GeneralHelpers: ObservableObject {
    static var shared: GeneralHelpers = GeneralHelpers()
    let userDefaults = UserDefaults.standard
    
    
    /// changes the face transform from world coordinates to the camera's coordinates (https://developer.apple.com/forums/thread/131982)
    ///
    /// - Parameters:
    ///     - currentFaceTransform: the original face transform matrix (a 4x4 float matrix)
    ///     - frame: represents the current frame of the AR session
    ///
    /// - Returns:
    ///     - a 4x4 transform matrix representing the camera's coordinates.
    ///         - +x points down, +y points right, +z points into the screen
    public static func changeCoordinates(currentFaceTransform: simd_float4x4, frame: ARFrame) -> simd_float4x4 {
        let currentCameraTransform = frame.camera.transform

        let newFaceMatrix = SCNMatrix4.init(currentFaceTransform)

        let newCameraMatrix = SCNMatrix4.init(currentCameraTransform)
        let cameraNode = SCNNode()
        cameraNode.transform = newCameraMatrix

        let originNode = SCNNode()
        originNode.transform = SCNMatrix4Identity

        /// Converts a transform from the node’s local coordinate space to that of another node.
        let transformInCameraSpace = originNode.convertTransform(newFaceMatrix, to: cameraNode)

        return simd_float4x4(transformInCameraSpace)
    }
}


class Images {
    let neckRotationImage = Image("NeckRotation")
    let checkMark = Image("CheckMark")
}



/// for the face UV unwrapping
extension SCNMatrix4 {
    /**
     Create a 4x4 matrix from CGAffineTransform, which represents a 3x3 matrix
     but stores only the 6 elements needed for 2D affine transformations.
     
     [ a  b  0 ]       [ a  b  0  0 ]
     [ c  d  0 ]  -> [ c  d  0  0 ]
     [ tx ty 1 ]       [ 0  0  1  0 ]
     .                       [ tx ty 0  1 ]
     
     Used for transforming texture coordinates in the shader modifier.
     (Needs to be SCNMatrix4, not SIMD float4x4, for passing to shader modifier via KVC.)
     */
    init(_ affineTransform: CGAffineTransform) {
        self.init()
        m11 = Float(affineTransform.a)
        m12 = Float(affineTransform.b)
        m21 = Float(affineTransform.c)
        m22 = Float(affineTransform.d)
        m41 = Float(affineTransform.tx)
        m42 = Float(affineTransform.ty)
        m33 = 1
        m44 = 1
    }
}
