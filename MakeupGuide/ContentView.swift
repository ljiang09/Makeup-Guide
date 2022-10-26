/*
ContentView.swift
MakeupGuide
Created by Lily Jiang on 6/14/22

This file draws the UI of the AR session. This includes the AR stream, overlaid images, etc.
*/

import SwiftUI
import SceneKit
import ARKit


struct ContentView : View {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @ObservedObject var arManager = ARSessionManager.shared
    var soundHelpers = SoundHelper.shared
    @ObservedObject var sessionData = LogSessionData.shared
    @State private var showingCheckImage = false
    
    @State var voiceoverOn: Bool = UserDefaults.standard.bool(forKey: "VoiceoversOn")  // need this in tandem with the user defaults because otherwise the UI doesn't update
    
    var body: some View {
        return ZStack(alignment: .center) {
            ARViewContainer().edgesIgnoringSafeArea(.all)
            
            if (arManager.isTextShowing) {
                VStack {
                    Spacer()
                    
                    if (voiceoverOn) {
                        Spacer()
                        
                        Text(soundHelpers.latestAnnouncement)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    if arManager.isSkipButtonShowing1 {
                        Button(action: {
                            soundHelpers.interruptVoiceover() {
                                arManager.isSkipButtonShowing1 = false
                                
                                arManager.appIntro2()
                            }
                        }, label: {
                            Text("Done")
                                .padding(30)
                                .font(.system(size: UIScreen.main.bounds.width/13))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        })
                        .padding([.leading, .trailing], UIScreen.main.bounds.width/10)
                    } else if arManager.isSkipButtonShowing2 {
                        Button(action: {
                            soundHelpers.interruptVoiceover() {
                                arManager.isTextShowing = false
                                arManager.isSkipButtonShowing2 = false
                                
                                arManager.centerFaceFlow()
                            }
                        }, label: {
                            Text("Done")
                                .padding(30)
                                .font(.system(size: UIScreen.main.bounds.width/13))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        })
                        .padding([.leading, .trailing], UIScreen.main.bounds.width/10)
                    }
                }
            }
            
            
            
            /// check makeup button
//            if ((arManager.isCheckMakeupButtonShowing) && (!arManager.generatingFaceTextures2)) {
//                VStack {
//                    Spacer()
//
//                    Button(action: {
//                        arManager.setGeneratingFaceTextures2()
//                        sessionData.log(whichButton: "Check your makeup")
//                    }, label: {
//                        Text("Check your makeup")
//                            .padding(30)
//                            .font(.system(size: UIScreen.main.bounds.width/13))
//                            .foregroundColor(.black)
//                            .frame(maxWidth: .infinity)
//                            .background(Color.white)
//                            .clipShape(RoundedRectangle(cornerRadius: 20))
//                    })
//                    .padding([.leading, .trailing], UIScreen.main.bounds.width/10)
//                }
//            }
            
            if ((self.showingCheckImage) || (arManager.isCheckImageShowing)) {
                Images().checkMark
                    .resizable()
                    .frame(width: 200, height: 200)
                    .position(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
            }
            
//            Button(action: {
//                if (UserDefaults.standard.bool(forKey: "VoiceoversOn")) {
//                    arManager.interruptVoiceover()
//                    soundHelpers.announce(announcement: "Voiceover is off")    // TODO: for some reason this isn't working, when i added the `soundHelpers.announce(announcement: soundHelpers.latestAnnouncement)` below it broke
//
//                    voiceoverOn = false
//                    UserDefaults.standard.set(false, forKey: "VoiceoversOn")
//                } else {
//                    voiceoverOn = true
//                    UserDefaults.standard.set(true, forKey: "VoiceoversOn")
//                    soundHelpers.announce(announcement: "Voiceover is on")
//                    soundHelpers.announce(announcement: soundHelpers.latestAnnouncement)    // TODO: this doesn't get announced either.. hrm
//                }
//            }) {
//                if (voiceoverOn) {
//                    Text("Turn voiceover off")
//                        .foregroundColor(.black)
//                        .padding()
//                        .background(RoundedRectangle(cornerRadius: 10)
//                            .foregroundColor(Color(red: 200/255, green: 200/255, blue: 200/255))
//                        )
//                } else {
//                    Text("Turn voiceover on")
//                        .foregroundColor(.black)
//                        .padding()
//                        .background(RoundedRectangle(cornerRadius: 10)
//                            .foregroundColor(Color(red: 80/255, green: 1, blue: 50/255))
//                        )
//                }
//            }
//            .padding()
//            .position(x: UIScreen.main.bounds.width * 3/4, y: UIScreen.main.bounds.height / 15)
        }
    }
    
    func showCheckImage() {
        self.showingCheckImage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.showingCheckImage = false
        }
    }

}


struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARSCNView {
        return ARSessionManager.shared.sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
}
