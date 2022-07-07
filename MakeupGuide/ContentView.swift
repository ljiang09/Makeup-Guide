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
    @ObservedObject var arManager = ARSessionManager.shared
    @State private var showingCheckImage = false
    
    var body: some View {
        return ZStack(alignment: .center) {
            ARViewContainer().edgesIgnoringSafeArea(.all)
            
            
            if ((arManager.isButtonShowing) && (!arManager.generatingFaceTextures2)) {
                Button(action: {
                    arManager.setGeneratingFaceTextures2(setTo: true)
                }, label: {
                    Text("Check your makeup")
                        .padding(30)
                        .font(.system(size: 30))
                        .foregroundColor(.black)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                })
                .position(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height * 3/4)
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
