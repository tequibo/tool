import Cocoa
import SpriteKit
import SwiftUI
import Combine

class CanvasView: NSView {
	var skView: SKView!
	var consoleView: NSHostingView<ConsoleView>!
	var viewModel = SharedObject() // Instantiated once for sharing
	var isConsoleVisible = true
	private var cancellables = Set<AnyCancellable>()
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		setup()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setup()
	}
	
	private func setup() {
		skView = SKView(frame: self.bounds)
		skView.autoresizingMask = [.width, .height]
		self.addSubview(skView)
		
		// MARK: CONSOLE VIEW
		let console = ConsoleView(viewModel: viewModel)
		consoleView = NSHostingView(rootView: console)
		consoleView.frame = NSRect(x: 0, y: 0, width: self.bounds.width, height: 100)
		consoleView.autoresizingMask = [.width]
		self.addSubview(consoleView)
		
		// MARK: CREATE LOOP SCENE
//		let scene = LoopScene(size: skView.bounds.size, viewModel: viewModel)
		let scene = LoopScene(size: skView.bounds.size, viewModel: viewModel)
		scene.scaleMode = .resizeFill
		skView.ignoresSiblingOrder = true
		skView.preferredFramesPerSecond = 120
		skView.showsFPS = true
		skView.showsNodeCount = true
		skView.presentScene(scene)
		
		self.registerForDraggedTypes([.fileURL])
		self.window?.makeFirstResponder(self)
		
		// Observe the isConsoleVisible property
		viewModel.$isConsoleVisible
			.receive(on: RunLoop.main)
			.sink { [weak self] isVisible in
				self?.consoleView.isHidden = !isVisible
			}
			.store(in: &cancellables)
	}
	

	

	
	override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
		return .copy
	}
	
	override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
		let pasteboard = sender.draggingPasteboard
		if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
		   let scene = skView.scene as? LoopScene {
			
			let locationInView = sender.draggingLocation
			let locationInScene = skView.convert(locationInView, to: scene)
			
			scene.handleDroppedFiles(urls, at: locationInScene)
			return true
		}
		return false
	}
}


