//
//  StateType.swift
//  MakeupGuide
//
//  Created by Lily Jiang on 10/5/22.
//
//  Based on the architecture of Invisible Maps of OCCaM Lab https://github.com/occamLab/InvisibleMap/blob/master/InvisibleMapCreator2/State%20Machine/StateType.swift
//  For more information about state machine: https://gist.github.com/andymatuschak/d5f0a8730ad601bcccae97e8398e25b2


protocol StateType {
    /// Events are effectful inputs from the outside world which the state reacts to, described by some
    /// data type. For instance: a button being clicked, or some network data arriving.
    associatedtype InputEvent

    /// Commands are effectful outputs which the state desires to have performed on the outside world.
    /// For instance: showing an alert, transitioning to some different UI, etc.
    associatedtype OutputCommand

    /// In response to an event, a state may transition to some new value, and it may emit a command.
    /// This is equivalent to not mutating, but instead returning a new state value and the output commang
    /// `func handleEvent(event: InputEvent) -> (Self, OutputCommand)`
    mutating func handleEvent(event: InputEvent) -> [OutputCommand]

    // Traditional models often allow states to specific commands to be performed on entry or
    // exit. We could add that, or not.
}
