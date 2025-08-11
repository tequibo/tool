import Cocoa
import SpriteKit

class PromptView: NSView {
	var promptTextField: NSTextField!
	var stepsTextField: NSTextField!
	var generateButton: NSButton!

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		setupView()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupView()
	}

	private func setupView() {
		promptTextField = NSTextField(frame: NSRect(x: 20, y: 60, width: 200, height: 24))
		promptTextField.placeholderString = "Enter prompt"
		addSubview(promptTextField)

		stepsTextField = NSTextField(frame: NSRect(x: 20, y: 30, width: 200, height: 24))
		stepsTextField.placeholderString = "Enter steps"
		addSubview(stepsTextField)

		generateButton = NSButton(frame: NSRect(x: 230, y: 45, width: 100, height: 32))
		generateButton.title = "Generate"
		generateButton.target = self
		generateButton.action = #selector(generateButtonClicked)
		addSubview(generateButton)
	}

	@objc private func generateButtonClicked() {
		guard let parent = self.superview as? SKView,
			  let scene = parent.scene as? LoopScene else { return }
		
		let prompt = promptTextField.stringValue
		let steps = Int(stepsTextField.stringValue) ?? 20
		
//		scene.generateMagicLoop(prompt: prompt, steps: steps) { progress in
//			print("Generation progress: \(progress)")
//		}
	}


}
