/*
ContentView.swift
MakeupGuide
Created by Lily Jiang on 6/14/22

This file draws the UI of the AR session. This includes the AR stream, overlaid images, etc.
*/

import SwiftUI
import SceneKit
import ARKit

// is there a way to call the shared instance of the manager, inside the manager class? 
struct ContentView : View {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @ObservedObject var arManager = ARSessionManager.shared
    @ObservedObject var sessionData = LogSessionData.shared
    @State private var showingCheckImage = false
    
    @State var voiceoverOn: Bool = true
    
    var body: some View {
        return ZStack(alignment: .center) {
            ARViewContainer().edgesIgnoringSafeArea(.all)
            
            if (arManager.isIntroTextShowing) {
                VStack {
                    HStack {
                        Spacer()
                        
//                        Button(action: {
//                            if (UserDefaults.standard.bool(forKey: "VoiceoversOn")) {
//                                print("voiceover is now false")
//                                UserDefaults.standard.set(false, forKey: "VoiceoversOn")
//                                // TODO: state that announcements are on
//                            } else {
//                                print("voiceover is now true")
//                                UserDefaults.standard.set(true, forKey: "VoiceoversOn")
//                                // TODO: state that announcements are off
//                            }
//                        }) {
//                            if (UserDefaults.standard.bool(forKey: "VoiceoversOn")) {
//                                Text("turn voiceover off")
//                            } else {
//                                Text("turn voiceover on")
//                            }
//                        }
//                        .padding()
                        
                        Button(action: {
                            if (voiceoverOn) {
                                print("voiceover is now false")
                                voiceoverOn = false
                                // TODO: state that announcements are on
                            } else {
                                print("voiceover is now true")
                                voiceoverOn = true
                                // TODO: state that announcements are off
                            }
                        }) {
                            if (voiceoverOn) {
                                Text("turn voiceover off")
                            } else {
                                Text("turn voiceover on")
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    Text(arManager.introText)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.5))
                    
                    Spacer()
                    
                    Button(action: {
                        arManager.isIntroTextShowing = false
                        arManager.interruptVoiceover()
                        arManager.runAtBeginning2()
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
            
            if ((arManager.isButtonShowing) && (!arManager.generatingFaceTextures2)) {
                VStack {
                    Spacer()
                    
                    Button(action: {
                        arManager.setGeneratingFaceTextures2(setTo: true)
                        sessionData.log(whichButton: "Check your makeup")
                    }, label: {
                        Text("Check your makeup")
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
            
            
            if (arManager.isNeckImageShowing) {
                Images().neckRotationImage
                    .resizable()
                    .frame(width: 200, height: 200)
                    .position(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
                    .onDisappear {
                        showCheckImage()
                    }
            }
            
            if ((self.showingCheckImage) || (arManager.isCheckImageShowing)) {
                Images().checkMark
                    .resizable()
                    .frame(width: 200, height: 200)
                    .position(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
            }
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
