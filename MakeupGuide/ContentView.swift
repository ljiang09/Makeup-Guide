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
            
            Button(action: {
                print("run code to get 3 more UV maps. then run code to compare the two")
                // i think this needs to be in the form of changing an observed variable in the ar sessio nmanager? and when it is set to true then run code in the renderer()? idk
            }, label: {
                Text("Check your makeup")
                    .padding(30)
                    .font(.system(size: 30))
                    .foregroundColor(.black)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            })
            .position(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height * 3/4)
            
            
            if arManager.isNeckImageShowing {
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
