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
import SDDownloadManager

class ViewController: UIViewController, ARSCNViewDelegate, URLSessionDelegate {
    
    // https://medium.com/ar-tips-and-tricks/how-to-add-arkit-ar-reference-images-from-the-internet-on-the-fly-eae3bc55fe0c
    // https://stackoverflow.com/questions/52154892/adding-reference-images-to-arkit-from-the-app

    @IBOutlet var sceneView: ARSCNView!
    var videoNode: SKVideoNode!
    var videoPlayer: AVPlayer!
    
    var internalPath: String = ""
    let videoExternalURL: URL = URL(string: "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")!
    let imageExternalURL =  "https://midiacode.com/assets/images/robin-worrall-fpt10lxk0cg-unsplash-1024x683.jpg"
        
    /// Returns The Documents Directory
    ///
    /// - Returns: URL
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        print(paths)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
        
    /// Creates A Set Of ARReferenceImages From All PNG Content In The Documents Directory
    ///
    /// - Returns: Set<ARReferenceImage>
    func loadedImagesFromDirectoryContents() -> Set<ARReferenceImage>? {
        var index = 0
        var customReferenceSet = Set<ARReferenceImage>()
        let documentsDirectory = getDocumentsDirectory()
        let str = documentsDirectory.absoluteString + "imagesARforTracking/"
        let imagesDirectory = URL(string: str)!
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: nil, options: [])
            let filteredContents = directoryContents.filter{ $0.pathExtension == "jpg" }
            print("Images found: \(filteredContents.count)")
            filteredContents.forEach { (url) in
                do {
                    //1. Create A Data Object From Our URL
                    let imageData = try Data(contentsOf: url)
                    guard let image = UIImage(data: imageData) else { return }
                    //2. Convert The UIImage To A CGImage
                    guard let cgImage = image.cgImage else { return }
                    //3. Get The Width Of The Image
                    let imageWidth = CGFloat(4) //CGFloat(cgImage.width)
                    print(imageWidth)
                    //4. Create A Custom AR Reference Image With A Unique Name
                    let customARReferenceImage = ARReferenceImage(cgImage, orientation: CGImagePropertyOrientation.up, physicalWidth: imageWidth)
                    customARReferenceImage.name = "AR Resource\(index)"
                    //4. Insert The Reference Image Into Our Set
                    customReferenceSet.insert(customARReferenceImage)
                    print("ARReference Image == \(customARReferenceImage)")
                    index += 1
                } catch {
                    print("Error Generating Images == \(error)")
                }
            }
        } catch {
            print("Error Reading Directory Contents == \(error)")
        }
        //5. Return The Set
        return customReferenceSet
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let request = URLRequest.init(url: URL.init(string: imageExternalURL)!)
//        let downloadKey = SDDownloadManager.shared.downloadFile(
//            withRequest: request,
//            inDirectory: "imagesARforTracking",
//            withName: nil,
//            onCompletion: { [weak self] (error, url) in
//            if let error = error {
//                print("Error is \(error as NSError)")
//            } else {
//                if let url = url {
//                    print("Downloaded file's url is \(url.path)")
//                    self?.internalPath = url.path
//                }
//            }
//        })
//        print("The key is \(downloadKey!)")
        
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
        
//        guard let arImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else { return }
        
        let detectionImages = loadedImagesFromDirectoryContents()
        configuration.trackingImages = detectionImages!

        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
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
