/*
CheckFaceHelper.swift
MakeupGuide
Created by Lily Jiang on 6/10/22

This file holds 2 helper functions to check face position and orientation
*/

import Darwin


enum FacePositions: String {
    case left = "left"
    case right = "right"
    case bottom = "bottom"
    case top = "top"
    case center = "center"
}

enum FaceOrientations: String {
    case slightlyLeft = "slightly left"
    case slightlyRight = "slightly right"
    case slightlyUp = "slightly up"
    case slightlyDown = "slightly down"
    case slightlyUpLeft = "slightly up left"
    case slightlyDownLeft = "slightly down left"
    case slightlyUpRight = "slightly up right"
    case slightlyDownRight = "slightly down right"
    case left = "left"
    case right = "right"
    case up = "up"
    case down = "down"
    case upLeft = "up left"
    case downLeft = "down left"
    case upRight = "up right"
    case downRight = "down right"
    case center = "center"
}



class CheckFaceHelper {
    static let shared: CheckFaceHelper = CheckFaceHelper()
    
    var orientation: FaceOrientations? = nil
    var position: FacePositions? = nil
    
    let centeredThreshold: Float = 0.1  // this bounds the center radius
    let slightlyThreshold: Float = 0.3  // this and the centered threshold bound the slightly left/right
    
    /// gets the orientation of the face (tilt, rotated left, etc), sets the variable to be accessed by the AR session manager
    func getOrientation(faceTransform: [[Float]]) {
        let horizontal = self.getHorizontalOrientation(faceTransform: faceTransform)
        var vertical = self.getVerticalOrientation(faceTransform: faceTransform)
        
        // move the "center" slightly up
        vertical = vertical + 0.08
        
        // convert to polar coordinates. will give us quadrant and magnitude
        let radius = sqrt(horizontal*horizontal + vertical*vertical)
        let angle = atan(vertical/horizontal) * (180 / 3.141)    // in degrees
        
        if radius < centeredThreshold {
            // face is centered
            print("face is centered!")
            orientation = FaceOrientations.center
        } else if centeredThreshold...slightlyThreshold ~= radius {
            // arctan goes from -90 to 90, so check that range and distinguish the quadrant based on the components' signs
            // note that the angle is kinda flipped.. since the positive horizontal is towards the left, and positive vertical is towards the bottom
            
            // there are 8 "sections" to consider, so divide by 45 degree segments
            if horizontal < 0 {
                // face is turned in the general right direction
                if -22.5...22.5 ~= angle {
                    print("face is turned slightly right")
                    orientation = FaceOrientations.slightlyRight
                } else if 22.5...67.5 ~= angle {
                    print("face is slightly tilted up and turned right")
                    orientation = FaceOrientations.slightlyUpRight
                } else if 67.5...90 ~= angle {
                    print("face is slightly tilted up")
                    orientation = FaceOrientations.slightlyUp
                } else if (-67.5)...(-22.5) ~= angle {
                    print("face is slightly tilted down and turned right")
                    orientation = FaceOrientations.slightlyDownRight
                } else if (-90)...(-67.5) ~= angle {
                    print("face is slightly tilted down")
                    orientation = FaceOrientations.slightlyDown
                }
            } else {
                // face is turned in the general left direction
                if -22.5...22.5 ~= angle {
                    print("face is slightly turned left")
                    orientation = FaceOrientations.slightlyLeft
                } else if 22.5...67.5 ~= angle {
                    print("face is slightly tilted down and turned left")
                    orientation = FaceOrientations.slightlyDownLeft
                } else if 67.5...90 ~= angle {
                    print("face is slightly tilted down")
                    orientation = FaceOrientations.slightlyDown
                } else if (-67.5)...(-22.5) ~= angle {
                    print("face is slightly tilted up and turned left")
                    orientation = FaceOrientations.slightlyUpLeft
                } else if (-90)...(-67.5) ~= angle {
                    print("face is slightly tilted up")
                    orientation = FaceOrientations.slightlyUp
                }
            }
        } else {
            if horizontal < 0 {
                // face is turned in the general right direction
                if -22.5...22.5 ~= angle {
                    print("face is turned right")
                    orientation = FaceOrientations.right
                } else if 22.5...67.5 ~= angle {
                    print("face is tilted up and turned right")
                    orientation = FaceOrientations.upRight
                } else if 67.5...90 ~= angle {
                    print("face is tilted up")
                    orientation = FaceOrientations.up
                } else if (-67.5)...(-22.5) ~= angle {
                    print("face is tilted down and turned right")
                    orientation = FaceOrientations.downRight
                } else if (-90)...(-67.5) ~= angle {
                    print("face is tilted down")
                    orientation = FaceOrientations.down
                }
            } else {
                // face is turned in the general left direction
                if -22.5...22.5 ~= angle {
                    print("face is turned left")
                    orientation = FaceOrientations.left
                } else if 22.5...67.5 ~= angle {
                    print("face is tilted down and turned left")
                    orientation = FaceOrientations.downLeft
                } else if 67.5...90 ~= angle {
                    print("face is tilted down")
                    orientation = FaceOrientations.down
                } else if (-67.5)...(-22.5) ~= angle {
                    print("face is tilted up and turned left")
                    orientation = FaceOrientations.upLeft
                } else if (-90)...(-67.5) ~= angle {
                    print("face is tilted up")
                    orientation = FaceOrientations.up
                }
            }
        }
    }
    
    
    private func getHorizontalOrientation(faceTransform: [[Float]]) -> Float {
        return faceTransform[0][2]
    }
    
    
    private func getVerticalOrientation(faceTransform: [[Float]]) -> Float {
        return faceTransform[1][2]
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
    private func returnThresholds(z: Float) -> [Float] {
        let thresholdScalars: [Float] = returnThresholdScalars(z: z)
        
        let bottomTH: Float = thresholdScalars[0] * z
        let topTH: Float = thresholdScalars[1] * z
        let rightTH: Float = thresholdScalars[2] * z
        let leftTH: Float = thresholdScalars[3] * z
        
        return [bottomTH, topTH, rightTH, leftTH]
    }
    
    /// this function is a helper function for `returnThresholds()`
    /// note that the equations for the scalar were measured to where the phone stops detecting a face entirely, so when the thresholds are used, it's shrunk 25% in order to create a smaller valid screen area
    private func returnThresholdScalars(z: Float) -> [Float] {
        let bottomScalar: Float = 0.520182*z - 0.324279
        let topScalar: Float = -0.467471*z + 0.458133
        let rightScalar: Float = 0.14423*z - 0.218682
        let leftScalar: Float = -0.143561*z + 0.226603
        
        return [bottomScalar, topScalar, rightScalar, leftScalar]
    }

}
