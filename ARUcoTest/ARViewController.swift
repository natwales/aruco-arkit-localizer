/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import UIKit
import SceneKit
import ARKit
import GLKit

let MARKER_SIZE_IN_METERS : CGFloat = 0.132953125; //set this to size of physically printed marker in meters


enum ObjectTypes: String {
    case box = "box"
    case cone = "cone"
    case sphere = "sphere"
}

class ARViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
	
    @IBOutlet weak var sessionInfoView: UIView!
	@IBOutlet weak var sessionInfoLabel: UILabel!
	@IBOutlet weak var sceneView: ARSCNView!
    
    private let dropButton = UIButton()
    private let saveButton = UIButton()
    private let loadButton = UIButton()
    private let testCVButton = UIButton()

    private var captureNextFrameForCV = false; //when set to true, frame is processed by opencv for marker
    private var localizedContentNode = SCNNode() //scene node positioned at marker to hold scene contents. Likely should be replaced with setWorldOrigin() in ios 11.3.
    private var markerOriginNode = MarkerOrigin(markerSize: MARKER_SIZE_IN_METERS) //display item to show over marker
    
    private var isLocalized = false {
        didSet {
            dropButton.isHidden = !isLocalized
            saveButton.isHidden = !isLocalized
            loadButton.isHidden = !isLocalized
            
            let message = isLocalized == true ? "re-localize" : "localize"
            testCVButton.setTitle(message, for: .normal)
        }
    }

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addButtons();
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initARKit()
       // let marker23 = OpenCVWrapper.getMarkerForId(23);
        isLocalized = false;
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    
    // MARK: - UI Handlers
    
    @IBAction func addObjectButtonTapped(sender: UIButton) {
        guard let cameraTransform = getCameraTransform(sceneView: sceneView) else {
            print("no camera!");
            return;
        }
        
        //renderTargetMarkerTest(transform: cameraTransform, node: localizedContentNode)
        let newTrans = sceneView.scene.rootNode.convertTransform(cameraTransform, to: localizedContentNode )
        addSceneObject(transform: newTrans, node: localizedContentNode)
    }
    
    @IBAction func saveButtonTapped(sender: UIButton) {
        
        var sceneObjects:[CodableSceneObject] = []
        
        for node in localizedContentNode.childNodes {
            if let node = node as? RedBox {
                let cso = CodableSceneObject(matrix: node.transform, objectId: ObjectTypes.box.rawValue)
                sceneObjects.append(cso)
            }
        }
        
        if sceneObjects.count > 0 {
            if ObjectStoreService.saveSceneObjects(objects: sceneObjects) {
                showAlert(title: "Scene Saved", message: "Your scene has been saved locally. Restart the app to load in the scene.")
            } else {
                showAlert(title: "Error", message: "Something went wrong. Your scene was not saved.")
            }
        }
        
    }
    
    @IBAction func loadButtonTapped(sender:UIButton) {
        
        guard let sceneObjects = ObjectStoreService.loadSceneObjects() else {
            showAlert(title: "Loading Error", message: "No locally stored scene was found. Try saving a scene first.")
            return
        }
        print("loaded scene objects")

        //todo clear existing sceneObjects
        for node in localizedContentNode.childNodes {
            if let node = node as? RedBox {
                node.removeFromParentNode()
            }
        }
       
        for sceneObject in sceneObjects {
            if(sceneObject.id == ObjectTypes.box.rawValue) {
                addSceneObject(transform: sceneObject.transform, node: localizedContentNode)
            }
        }
        
        showAlert(title: "Scene Loaded", message: "The last saved scene has been loaded. All objects should appear in the same positions relative to marker.")
    }
    
    @IBAction func testCVButtonTapped(sender:UIButton) {
        captureNextFrameForCV = true;
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }

    // MARK: - ARSessionObserver
	
	func sessionWasInterrupted(_ session: ARSession) {
		// Inform the user that the session has been interrupted, for example, by presenting an overlay.
		sessionInfoLabel.text = "Session was interrupted"
	}
	
	func sessionInterruptionEnded(_ session: ARSession) {
		// Reset tracking and/or remove existing anchors if consistent tracking is required.
		sessionInfoLabel.text = "Session interruption ended"
		resetTracking()
	}
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        resetTracking()
    }
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if(self.captureNextFrameForCV != false) {
            updateCameraPose(frame: frame)
            self.captureNextFrameForCV = false
        }
    }

    // MARK: - Private methods
    
    private func initARKit() {
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """)
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        configuration.worldAlignment = .gravity
        sceneView.session.run(configuration)
        sceneView.autoenablesDefaultLighting = true;
        
        sceneView.session.delegate = self
        UIApplication.shared.isIdleTimerDisabled = true
        sceneView.showsStatistics = true
        
    }
    
    private func updateCameraPose(frame: ARFrame) {
        let pixelBuffer = frame.capturedImage
       
        //this this is matrix from camera to target
        let transMatrix = OpenCVWrapper.transformMatrix(from: pixelBuffer, withIntrinsics: frame.camera.intrinsics, andMarkerSize: Float64(MARKER_SIZE_IN_METERS));
        
        //quick and dirty error checking. if it's an identity matrix no marker was found.
        if(SCNMatrix4IsIdentity(transMatrix)) {
            print("no marker found")
            return;
        }
        
        let cameraTransform = SCNMatrix4.init(frame.camera.transform);
        let targTransform = SCNMatrix4Mult(transMatrix, cameraTransform);
        
        //strange behavior leads me to believe that the scene updates should occur in main dispatch que. (or perhaps I should be using anchors)
        DispatchQueue.main.async {
            self.updateContentNode(targTransform: targTransform)
        }
        
        isLocalized = true;
        //we want to use transMatrix to position arWaypoint anchor on marker.
    }
    
    private func updateContentNode(targTransform: SCNMatrix4) {
        //renderTargetMarkerTest(transform:targTransform, node: sceneView.scene.rootNode);
        
        if !sceneView.scene.rootNode.childNodes.contains(localizedContentNode) {
            sceneView.scene.rootNode.addChildNode(localizedContentNode);
        }
        
        if !localizedContentNode.childNodes.contains(markerOriginNode) {
            localizedContentNode.addChildNode(markerOriginNode)
            markerOriginNode.eulerAngles.x = .pi / 2
        }
        
        localizedContentNode.setWorldTransform(targTransform);
    }
    
    private func addSceneObject(transform:SCNMatrix4, node:SCNNode) {
        let box = RedBox();
        node.addChildNode(box)
        box.transform = transform
        box.eulerAngles.x += .pi / 2 //confirm rotation, hard to tell with cube. I think this is correct though, maybe it doesn't matter
    }
    
    private func getCameraTransform(sceneView:ARSCNView) -> SCNMatrix4? {
        guard let curFrame = sceneView.session.currentFrame else {
            return nil;
        }
        return SCNMatrix4.init(curFrame.camera.transform);
    }

    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String

        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move the device around to detect horizontal surfaces."
        case .normal:
            // No feedback needed when tracking is normal and planes are visible.
            message = ""
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing):
            message = "Initializing AR session."
        }

        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
        testCVButton.isHidden = !message.isEmpty
    }

    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        for node in localizedContentNode.childNodes {
            node.removeFromParentNode()
        }
        
        localizedContentNode.removeFromParentNode()
    }
    
    private func addButtons() {
        
        let buttonHolder = UIView();
        buttonHolder.translatesAutoresizingMaskIntoConstraints = false
        
        buttonHolder.addSubview(dropButton)
        dropButton.translatesAutoresizingMaskIntoConstraints = false
        dropButton.setTitle("Add Object", for: .normal)
        dropButton.setTitleColor(UIColor.cyan, for: .normal)
        dropButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dropButton.addTarget(self, action: #selector(addObjectButtonTapped(sender:)), for: .touchUpInside)
        
        buttonHolder.addSubview(saveButton)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(UIColor.black, for: .normal)
        saveButton.backgroundColor = UIColor.cyan.withAlphaComponent(0.4)
        saveButton.addTarget(self, action: #selector(saveButtonTapped(sender:)), for: .touchUpInside)
        
        buttonHolder.addSubview(loadButton)
        loadButton.translatesAutoresizingMaskIntoConstraints = false
        loadButton.setTitle("Load", for: .normal)
        loadButton.setTitleColor(UIColor.black, for: .normal)
        loadButton.backgroundColor = UIColor.cyan.withAlphaComponent(0.4)
        loadButton.addTarget(self, action: #selector(loadButtonTapped(sender:)), for: .touchUpInside)
        
        buttonHolder.addSubview(testCVButton)
        testCVButton.translatesAutoresizingMaskIntoConstraints = false
        testCVButton.setTitle("Localize", for: .normal)
        testCVButton.setTitleColor(UIColor.black, for: .normal)
        testCVButton.backgroundColor = UIColor.cyan.withAlphaComponent(0.4)
        testCVButton.addTarget(self, action: #selector(testCVButtonTapped(sender:)), for: .touchUpInside)
        
        view.addSubview(buttonHolder)
        
        //constraints
        buttonHolder.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30).isActive = true
        buttonHolder.leftAnchor.constraint(equalTo: testCVButton.leftAnchor, constant: 0).isActive = true
        buttonHolder.rightAnchor.constraint(equalTo: dropButton.rightAnchor, constant: 0).isActive = true
        buttonHolder.heightAnchor.constraint(equalToConstant: 50).isActive = true
        buttonHolder.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        
        dropButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        saveButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        loadButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        testCVButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        
        dropButton.bottomAnchor.constraint(equalTo: buttonHolder.bottomAnchor).isActive = true
        loadButton.bottomAnchor.constraint(equalTo: buttonHolder.bottomAnchor).isActive = true
        saveButton.bottomAnchor.constraint(equalTo: buttonHolder.bottomAnchor).isActive = true
        testCVButton.bottomAnchor.constraint(equalTo: buttonHolder.bottomAnchor).isActive = true
        
        saveButton.leadingAnchor.constraint(equalTo: testCVButton.trailingAnchor, constant: 20).isActive = true
        loadButton.leadingAnchor.constraint(equalTo: saveButton.trailingAnchor, constant: 20).isActive = true
        dropButton.leadingAnchor.constraint(equalTo: loadButton.trailingAnchor, constant: 20).isActive = true
        
        dropButton.topAnchor.constraint(equalTo: buttonHolder.topAnchor).isActive = true
        saveButton.topAnchor.constraint(equalTo: buttonHolder.topAnchor).isActive = true
        loadButton.topAnchor.constraint(equalTo: buttonHolder.topAnchor).isActive = true
        testCVButton.topAnchor.constraint(equalTo: buttonHolder.topAnchor).isActive = true
        
    }
    
    private func showAlert(title:String, message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
