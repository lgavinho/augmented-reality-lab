//
//  ViewController.swift
//  ARdemo1
//
//  Created by Luiz Gustavo Gavinho on 10/09/20.
//  Copyright © 2020 Luiz Gustavo Gavinho. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var videoNode: SKVideoNode!
    var videoPlayer: AVPlayer!
    
    let videoExternalURL: URL = URL(string: "https://www.youtube.com/watch?v=Kty2sgZdpRo")!
    let imageExternalURL: URL = URL(string: "https://midiacode.com/assets/images/robin-worrall-fpt10lxk0cg-unsplash-1024x683.jpg")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        try! AVAudioSession.sharedInstance().setCategory(.playback)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        
        guard let arImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else { return }
        
        configuration.trackingImages = arImages

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARImageAnchor else { return }
        
        guard let referenceImage = ((anchor as? ARImageAnchor)?.referenceImage) else { return }
        
        guard let container = sceneView.scene.rootNode.childNode(withName: "container", recursively: false) else { return }
        
        container.removeFromParentNode()
        node.addChildNode(container)
        container.isHidden = false
        
//        guard let videoURL = Bundle.main.url(forResource: "video", withExtension: ".mp4") else { return }
        let videoURL = videoExternalURL
        videoPlayer = AVPlayer(url: videoURL)
        
        let videoScene = SKScene(size: CGSize(width: 720.0, height: 1280.0))
        videoNode = SKVideoNode(avPlayer: videoPlayer)
        videoNode.position = CGPoint(x: videoScene.size.width/2, y: videoScene.size.height/2)
        videoNode.size = videoScene.size
        videoNode.yScale = -1
        videoNode.play()
        videoScene.addChild(videoNode)
        
        guard let video = container.childNode(withName: "video", recursively: true) else { return }
        video.geometry?.firstMaterial?.diffuse.contents = videoScene
        
        video.scale = SCNVector3(
            x: Float(referenceImage.physicalSize.width),
            y: Float(referenceImage.physicalSize.height),
            z: 1.0)
        
        video.position = node.position
        
        // For Animation
        guard let videoContainer = container.childNode(withName: "videoContainer", recursively: false) else { return }
        
        videoContainer.runAction(
            SCNAction.sequence(
                [SCNAction.wait(duration: 1.0), SCNAction.scale(to: 1.0, duration: 0.5)]))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = (anchor as? ARImageAnchor) else { return }
        
        if imageAnchor.isTracked {
           videoNode.play()
        } else {
           videoNode.pause()
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
