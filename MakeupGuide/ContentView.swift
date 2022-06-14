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
    var body: some View {
        return ZStack {
            ARViewContainer().edgesIgnoringSafeArea(.all)
        }
    }
}


struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARSCNView {
        
        return ARSessionManager.shared.sceneView
        
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
