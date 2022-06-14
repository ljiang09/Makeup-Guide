//
//  CheckFaceHelper.swift
//  MakeupGuide02
//
//  Created by Lily Jiang on 6/10/22.
//


class CheckFaceHelper {
    static func checkOrientationOfFace(transformMatrix: [[Float]]) -> String {
        /// thresholds for the `if` statements
        let th1: Float = 0.9
        let th2: Float = 0.3
    //    let th3: Float = 0.8
        let th4: Float = 0.5
    //    let th5: Float = 0.15
        
        if ((transformMatrix[0][1] < th1) && (transformMatrix[0][2] > th2)
            && (transformMatrix[2][1] < -th2) && (transformMatrix[2][2] < th1)) {
            // [0][1] 0.97 -> 0.78
            // [0][2] 0.12 -> 0.47
            // [2][1] -0.12 -> -0.47
            // [2][2] 0.99 -> 0.88
            return "Rotated Left"
        }
        if ((transformMatrix[0][1] < th1) && (transformMatrix[0][2] < -th2)
            && (transformMatrix[2][1] > th2) && (transformMatrix[2][2] < th1)) {
            // [0][1] 0.99 -> 0.90
            // [0][2] 0.15 -> -0.44
            // [2][1] -0.15 -> 0.44
            // [2][2] 0.99 -> 0.90
            return "Rotated Right"
        }
        if ((transformMatrix[1][0] > -th1) && (transformMatrix[1][2] > th4)
            && (transformMatrix[2][0] > th4) && (transformMatrix[2][2] < th1)) {
            // [1][0] -0.98 -> -0.81
            // [1][2] 0.20 -> 0.58
            // [2][0] 0.20 -> 0.58
            // [2][2] 0.98 -> 0.81
            return "Tilted Forward"
        }
        if ((transformMatrix[1][0] > -th1) && (transformMatrix[1][2] < -0.5) && (transformMatrix[2][0] < -0.5) && (transformMatrix[2][2] < th1)) {
            // [1][0] -1 -> -0.83
            // [1][2] 0 -> -0.55
            // [2][0] 0 -> -0.55
            // [2][2] 1 -> 0.83
            return "Tilted Backward"
        }

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
        
        return ""
    }





    static func checkPositionOfFace(transformMatrix: [[Float]]) -> String {
    //    let th1: Float = 0.1
    //    let th2: Float = 0.5
        
        if (transformMatrix[3][2] < -0.5) {
            return "Face is too far away, move closer"
        }
        
        // these definitely need to be changed based on how far away the face is from the camera
        if (transformMatrix[3][1] > 0.07) {
            return "Face is too far to the right"
        }
        if (transformMatrix[3][1] < -0.07) {
            return "Face is too far to the left"
        }
        if (transformMatrix[3][0] < -0.09) {
            return "Face is too far up"
        }
        if (transformMatrix[3][0] > 0.09) {
            return "Face is too far down"
        }
        
        return ""
    }

}
