/*
SoundHelpers.swift
MakeupGuide
Created by Lily Jiang on 6/21/22

This file holds all the helper functions to create sound (voiceovers, pings, etc)
    TTS code is from Clew https://github.com/occamLab/Clew/blob/ClewgleMaps/Clew/Misc/SoundEffectManager.swift
    For TTS, voiceover is preferred as it uses the user's settings, but an alternative is the coded version with a synthesizer
    TTS also has the ability to queue up a second string
*/

import AudioToolbox
import AVFoundation
import UIKit
import SwiftUI



class SoundHelper: NSObject {
    static var shared: SoundHelper = SoundHelper()
    let synthesizer = AVSpeechSynthesizer()     /// this should only be created once because it is memory intensive
    var player: AVAudioPlayer?
    
    /// the voiceover callouts for face positioning
    let rotateHeadInstructions = "slowly turn your head back and forth"
    let headPosRight = "face is too far right of the camera"
    let headPosLeft = "face is too far left of the camera"
    let headPosTop = "face is too high in the camera"
    let headPosBottom = "face is too low in the camera"
    let headRotateRight = "face is rotated right"
    let headRotateLeft = "face is rotated left"
    let headTiltUp = "face is tilted up"
    let headTiltDown = "face is tilted down"
    
    
    private var currentAnnouncement: String?        /// The announcement that is currently being read.  If this is nil, that implies nothing is being read
    private var nextAnnouncement: String?           /// The announcement that should be read immediately after this one finishes
    private var announcementRemovalTimer: Timer?    /// times when an announcement should be removed.  These announcements are displayed on the `announcementText` label.
    
    private override init() {
        super.init()
        
        synthesizer.delegate = self
        
        // create listeners to ensure that the isReadingAnnouncement flag is reset properly
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { (notification) -> Void in
            self.currentAnnouncement = nil
        }
        
        NotificationCenter.default.addObserver(forName: UIAccessibility.announcementDidFinishNotification, object: nil, queue: nil) { (notification) -> Void in
            self.currentAnnouncement = nil
            if let nextAnnouncement = self.nextAnnouncement {
                self.nextAnnouncement = nil
                self.announce(announcement: nextAnnouncement)
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil, queue: nil) { (notification) -> Void in
            self.currentAnnouncement = nil
        }
    }
    
    
    /// this plays a general sound from a file
    func playSound(soundName: String, dotExt: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: dotExt) else { return }

        do {
            /// make the sound play even if the ringer is turned off
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            if (dotExt == "wav") {
                player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
            } else if (dotExt == "mp3") {
                player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            }

            /// update the player variable
            guard let player = player else {
                print("audio file couldn't be loaded")
                return
            }

            player.play()

        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    
    
    /// Communicates a message to the user via speech.  If VoiceOver is active, then VoiceOver is used to communicate the announcement, otherwise we use the AVSpeechEngine
    ///
    /// - Parameter announcement: the text to read to the user
    func announce(announcement: String) {
        @ObservedObject var sessionData = LogSessionData.shared
        
        // ensure the code is running on the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.announce(announcement: announcement)
            }
            
            return
        }
        if let currentAnnouncement = currentAnnouncement {
            // don't interrupt current announcement, but if there is something new to say put it on the queue to say next.  Note that adding it to the queue in this fashion could result in the next queued announcement being preempted
            if currentAnnouncement != announcement {
                nextAnnouncement = announcement
            }
            
            return
        }
        
        // VoiceOver is the preferred option for TTS
        if UIAccessibility.isVoiceOverRunning {
//            print("voice over")
            currentAnnouncement = announcement
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: announcement)
        }
        // but if the user hasn't enabled VoiceOver, use a synthesizer
        else {
//            print("synthesizer")
            let audioSession = AVAudioSession.sharedInstance()
            
            do {
                // make the audio play even if the ringer is off
                try audioSession.setCategory(AVAudioSession.Category.playback)
                try audioSession.setActive(true)
                
                let utterance = AVSpeechUtterance(string: announcement)
                // change the utterance to be the local accent
                utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.languageCode)
                utterance.rate = 0.5
//                utterance.volume = 0.5
                currentAnnouncement = announcement
                synthesizer.speak(utterance)
            } catch {
                print("Unexpteced error announcing something using AVSpeechEngine!")
            }
        }
        
        sessionData.log(voiceOver: announcement)
    }
    
    
}









// MARK: - Synthesizer Delegate
extension SoundHelper: AVSpeechSynthesizerDelegate {
    /// Called when an utterance is finished.  We implement this function so that we can keep track of
    /// whether or not an announcement is currently being read to the user.
    ///
    /// - Parameters:
    ///   - synthesizer: the synthesizer that finished the utterance
    ///   - utterance: the utterance itself
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        currentAnnouncement = nil
        if let nextAnnouncement = self.nextAnnouncement {
            self.nextAnnouncement = nil
            announce(announcement: nextAnnouncement)
        }
    }
    /// Called when an utterance is canceled.  We implement this function so that we can keep track of
    /// whether or not an announcement is currently being read to the user.
    ///
    /// - Parameters:
    ///   - synthesizer: the synthesizer that finished the utterance
    ///   - utterance: the utterance itself
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didCancel utterance: AVSpeechUtterance) {
        currentAnnouncement = nil
        if let nextAnnouncement = self.nextAnnouncement {
            self.nextAnnouncement = nil
            announce(announcement: nextAnnouncement)
        }
    }
}
