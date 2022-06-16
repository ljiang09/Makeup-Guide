//
//  ContentView.swift
//  MakeupGuide
//
//  Created by Lily Jiang on 6/14/22.
//

import SwiftUI
import SceneKit
import ARKit


struct ContentView : View {
    @ObservedObject var arManager = ARSessionManager.shared
    @State private var showingCheckImage = false
    
    var body: some View {
        return ZStack {
            ARViewContainer().edgesIgnoringSafeArea(.all)
            
            if arManager.isNeckImageShowing {
                // TODO: voice telling them to position their head in the screen and move it side to side
                Images().neckRotationImage
                    .resizable()
                    .frame(width: 200, height: 200)
                    .position(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
                    .onDisappear {
                        showImage()
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
    
    private func showImage() {
        self.showingCheckImage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.showingCheckImage = false
            print("check image should disappear")
        }
    }
}


struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARSCNView {
        
        return ARSessionManager.shared.sceneView
        
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
}

//
//#if DEBUG
//struct ContentView_Previews : PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
//#endif
