/*
VCHelpers.swift
MakeupGuide
Created by Lily Jiang on 6/13/22

This file holds a helper function to convert the face anchor transform matrix from world to camera coordinates.
Note that the camera axes are oriented differently. +x points down and +y points to the right.
*/

import ARKit
import SwiftUI


/// change world coordinates to the coordinates of the camera
/// https://developer.apple.com/forums/thread/131982
/// Note that the new system has the x and y rotated 90 degrees CW.
func changeCoordinates(currentFaceTransform: simd_float4x4, frame: ARFrame) -> simd_float4x4 {
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


class Images {
    let neckRotationImage = Image("NeckRotation")
    let checkMark = Image("CheckMark")
}
