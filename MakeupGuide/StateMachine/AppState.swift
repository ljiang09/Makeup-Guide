//
//  AppState.swift
//  MakeupGuide
//
//  Created by Lily Jiang on 10/5/22.
//
//  Created based on "composable finite state machine" architecture of Invisible Maps of OCCaM lab https://github.com/occamLab/InvisibleMap/blob/master/InvisibleMapCreator2/State%20Machine/AppState.swift
//  https://docs.google.com/document/d/13iVLu6OGieQ8GTn1ysAw7daawXYnD5HghI6UZjw1c9s/edit#

import ARKit


enum AppState: StateType {
    // All the effectual inputs from the app which the state can react to. Ex: button being clicked, data from backend arriving, etc.
    enum Event {
        case AppStarted
        case ContinueButtonPressed
        case CenteringFace
        case CollectingImage(whichImage: String)
        case CheckMakeupButtonPressed
    }
    
    
    // All the effectful outputs which the state desires to have performed on the app. Ex: showing an alert, transitioning to a different UI, etc.
    enum Command {
        case DisplayInstructions1
        case DisplayInstructions2
        case CheckFaceCentered(faceTransform: [[Float]])
        case CollectImage(whichImage: String)
        case SendImageToFirebase(image: UIImage, name: String)
        case SendAnalyticsToFirebase
        
//        case CacheLocation(node: SCNNode, picture: UIImage, textNode: SCNNode)
//        case UpdateLocationList(node: SCNNode, picture: UIImage, textNode: SCNNode, poseId: Int)
//        case SendToFirebase(mapName: String)
//        case ClearData
    }
    
    
    // In response to an event, a state may transition to a new state, and it may emit a command
    mutating func handleEvent(event: Event) -> [Command] {
        switch (event) {
        case .AppStarted:
            print("[State Machine] App Starting")
            return [.DisplayInstructions1]
        case .ContinueButtonPressed:
            print("[State Machine] User pressed \"Continue\" button")
            return[.DisplayInstructions2]
        case .CenteringFace:
            print("[State Machine] Centering Face")
            return[]
        case .CollectingImage:
            print("[State Machine] Collecting Image")
            return[]
        case .CheckMakeupButtonPressed:
            print("[State Machine] User pressed \"Check Makeup\" button")
            return[]
        
        
//        case (.RecordMap(let state), _) where RecordMapState.Event(event) != nil:
//            var newState = state
//            let commands = newState.handleEvent(event: RecordMapState.Event(event)!)
//            self = .RecordMap(newState)
//            return commands
            
        default:
            break
        }
        return []
    }
}
