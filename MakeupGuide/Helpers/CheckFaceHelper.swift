/*
CheckFaceHelper.swift
MakeupGuide
Created by Lily Jiang on 6/10/22

This file holds 2 helper functions to check face position and orientation
*/


class CheckFaceHelper {
    static let shared: CheckFaceHelper = CheckFaceHelper()
    
    let rotatedLeft = "Face is rotated left"
    let rotatedRight = "Face is rotated right"
    let tiltedForward = "Face is tilted forward"
    let tiltedBackward = "Face is tilted backward"
    
    
    func checkOrientationOfFace(transformMatrix: [[Float]]) -> String {
        /// thresholds for the `if` statements
        let th1: Float = 0.9
        let th2: Float = 0.3
        let th3: Float = 0.5
        
        if ((transformMatrix[0][1] < th1) && (transformMatrix[0][2] > th2)
            && (transformMatrix[2][1] < -th2) && (transformMatrix[2][2] < th1)) {
            // [0][1] 0.97 -> 0.78
            // [0][2] 0.12 -> 0.47
            // [2][1] -0.12 -> -0.47
            // [2][2] 0.99 -> 0.88
            return rotatedLeft
        }
        if ((transformMatrix[0][1] < th1) && (transformMatrix[0][2] < -th2)
            && (transformMatrix[2][1] > th2) && (transformMatrix[2][2] < th1)) {
            // [0][1] 0.99 -> 0.90
            // [0][2] 0.15 -> -0.44
            // [2][1] -0.15 -> 0.44
            // [2][2] 0.99 -> 0.90
            return rotatedRight
        }
        if ((transformMatrix[1][0] > -th1) && (transformMatrix[1][2] > th3)
            && (transformMatrix[2][0] > th3) && (transformMatrix[2][2] < th1)) {
            // [1][0] -0.98 -> -0.81
            // [1][2] 0.20 -> 0.58
            // [2][0] 0.20 -> 0.58
            // [2][2] 0.98 -> 0.81
            return tiltedForward
        }
        if ((transformMatrix[1][0] > -th1) && (transformMatrix[1][2] < -0.5) && (transformMatrix[2][0] < -0.5) && (transformMatrix[2][2] < th1)) {
            // [1][0] -1 -> -0.83
            // [1][2] 0 -> -0.55
            // [2][0] 0 -> -0.55
            // [2][2] 1 -> 0.83
            return tiltedBackward
        }
        // TODO: make an if statement to figure out if the face is in the screen at all, if it is head on. BC right now, headOn and not in screen are the saem, represented by "blank"
        

        /// I commented all these out because I don't think tilt left/right matters
        /// note (6/13/2022): I changed the transform matrix to be in the camera's coordinates so some of these values may be outdated
        /*if ((transformMatrix[0][0] < th1) && (transformMatrix[0][1] > th2)
            && (transformMatrix[1][0] < -th2) && (transformMatrix[1][1] < th1)) {
    //            [0][0] 1 -> 0.86
    //            [0][1] 0 -> 0.5
    //            [1][0] 0 -> -0.62
    //            [1][1] 0.96 -> 0.76
            return "Tilted Left"
        }
        if ((transformMatrix[0][0] < th1) && (transformMatrix[0][1] < -th2)
            && (transformMatrix[1][0] > th2) && (transformMatrix[1][1] < th1)) {
    //            [0][0] 1 -> 0.8
    //            [0][1] -0.1 -> -0.6
    //            [1][0] 0.013 -> 0.65
    //            [1][1] 0.93 -> 0.72
            return "Tilted Right"
        }*/
        
        return "blank"
    }





    func checkPositionOfFace(transformMatrix: [[Float]]) -> String {
        let thresholds = returnThresholds(z: transformMatrix[3][2])
        
        if (transformMatrix[3][2] < -0.75) {
            return "Face is too far away, move closer"
        }
        
        // these definitely need to be changed based on how far away the face is from the camera
        if (transformMatrix[3][1] > thresholds[2]*0.75) {
            return "Face is too far to the right"
        }
        if (transformMatrix[3][1] < thresholds[3]*0.75) {
            return "Face is too far to the left"
        }
        if (transformMatrix[3][0] < thresholds[1]*0.75) {
            return "Face is too far up"
        }
        if (transformMatrix[3][0] > thresholds[0]*0.75) {
            return "Face is too far down"
        }
        if ((thresholds[1]*0.75...thresholds[0]*0.75 ~= transformMatrix[3][0]) && (thresholds[3]*0.75...thresholds[2]*0.75 ~= transformMatrix[3][1])) {
            return "Face is centered"
        }
        
        return "blank"  // note that this is only useful at the very beginning before teh value has been populated. because it will never become populated iwth "blank" again
    }
    
    
    /// this function finds the horizontal and vertical bounds for the person's face in the screen, based purely on the z value.
    fileprivate func returnThresholds(z: Float) -> [Float] {
        let thresholdScalars: [Float] = returnThresholdScalars(z: z)
        
        let bottomTH: Float = thresholdScalars[0] * z
        let topTH: Float = thresholdScalars[1] * z
        let rightTH: Float = thresholdScalars[2] * z
        let leftTH: Float = thresholdScalars[3] * z
        
        return [bottomTH, topTH, rightTH, leftTH]
    }
    
    /// this function is a helper function for `returnThresholds()`
    /// note that the equations for the scalar were measured to where the phone stops detecting a face entirely, so when the thresholds are used, it's shrunk 25% in order to create a smaller valid screen area
    fileprivate func returnThresholdScalars(z: Float) -> [Float] {
        let bottomScalar: Float = 0.520182*z - 0.324279
        let topScalar: Float = -0.467471*z + 0.458133
        let rightScalar: Float = 0.14423*z - 0.218682
        let leftScalar: Float = -0.143561*z + 0.226603
        
        return [bottomScalar, topScalar, rightScalar, leftScalar]
    }

}
