import Cocoa
import SpriteKit
import AVFoundation

class ViewController: NSViewController {

	@IBOutlet var skView: SKView!
	public var session: AVCaptureSession?

	var canvasView: CanvasView!

	override func viewDidLoad() {
		super.viewDidLoad()

		// Create and setup CanvasView
		canvasView = CanvasView(frame: self.view.bounds)
		canvasView.autoresizingMask = [.width, .height]

		self.view.addSubview(canvasView)

		// Present the CanvasScene in CanvasView's SKView
		if let skView = canvasView.skView {
//			let scene = LoopScene(size: skView.bounds.size)
//			scene.scaleMode = .resizeFill
//			skView.presentScene(scene)
//			skView.ignoresSiblingOrder = true
//			skView.preferredFramesPerSecond = 120
//			skView.showsFPS = true
//			skView.showsNodeCount = true
			
//			let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
//			skView.addGestureRecognizer(panGesture)
		}
	}

//	@objc func handlePan(_ gesture: NSPanGestureRecognizer) {
//		let translation = gesture.translation(in: view)
//		// Handle the two-finger pan gesture translation here
//		print("Pan gesture translation: \(translation)")
//	}
}
