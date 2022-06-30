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
        return ZStack {
            ARViewContainer().edgesIgnoringSafeArea(.all)
            
            Button("Export Texture Map", action: {
                print("exported")
                arManager.exportTextureMapToPhotos()
            })
            
            if arManager.isNeckImageShowing {
                // TODO: voice telling them to position their head in the screen and move it side to side
                Images().neckRotationImage
                    .resizable()
                    .frame(width: 200, height: 200)
                    .position(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
                    .onDisappear {
                        showCheckImage()
                    }
            }
            
            if self.showingCheckImage {
                Images().checkMark
                    .resizable()
                    .frame(width: 200, height: 200)
                    .position(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
            }
        }
    }
    
    private func showCheckImage() {
        self.showingCheckImage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
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
