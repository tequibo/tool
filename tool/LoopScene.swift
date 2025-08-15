import SpriteKit
import AVFoundation
import Foundation
import Cocoa
import Combine

import AudioKit
import AudioKitUI
import SoundpipeAudioKit

import CoreMIDI
import GameController
var GLOBAL: Double = 60.0
class LoopScene: SKScene, SKPhysicsContactDelegate {
	//	var loopViewModel: LoopViewModel
	
	var viewModel: SharedObject
	
	init(size: CGSize, viewModel: SharedObject) {
		self.viewModel = viewModel
		super.init(size: size)
		//		self.viewModel.$data.sink { [weak self] newData in
		//			self?.updateScene(with: newData)
		//		}.store(in: &cancellables)
		self.viewModel.$prompt.sink { [weak self] newData in
			self?.prompt = newData
		}.store(in: &cancellables)
		self.viewModel.$steps.sink { [weak self] newData in
			self?.steps = Int(newData)
			
		}.store(in: &cancellables)
		self.viewModel.$angle.sink { [weak self] newData in
			self?.angle = newData
		}.store(in: &cancellables)
		self.viewModel.$fpsExport.sink { [weak self] newData in
			self?.framesToExport = Int(newData*self!.loopTime)
		}.store(in: &cancellables)
		self.viewModel.$fps.sink { [weak self] newData in
			self?.fps = newData
		}.store(in: &cancellables)
		self.viewModel.$loopTime.sink { [weak self] newData in
			self?.loopTime = newData
		}.store(in: &cancellables)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	//	private var oscillator: Oscillator!
	//	private var lfo: Oscillator!
	//	private var mixer: Mixer!
	//	internal var audioEngine: AudioEngine!
    enum Modes {
        case drag
        case record
        case writeChange
    }
	private var duplicateCounter = 0
	private var isBlack = false
	private var duplicateKeyPressed = false
    var editorMode = Modes.drag
    var time:TimeInterval = 0
    var prevTime:TimeInterval = 0

	var isPainting = false
	private var cancellables = Set<AnyCancellable>()
	var dateTimeString = ""
	var selectionLock = false
	var prompt: String = ""
	var steps: Int = 5
	var angle = Float.tau/24
	var fps = 30
	var framesToExport = 0
	var magicLoop: MagicLoop?
	var presetDirectoryPath: URL = URL(fileURLWithPath: "/Users/sasha/loops/active")
	var draggingNode: SKNode?
	var selectedBrush: MagicLoop?
	var initialPosition: CGPoint = .zero
	var isPressed: Bool = false
	var lastDraggedNode: SKNode?
	var lastPlayer: AVQueuePlayer?
	var mousePosition: CGPoint = .zero
	var magicLoops: [MagicLoop] = [] // List to keep track of MagicLoop instances
    var magicLoopsNumbered: [MagicLoop] = [] // List to keep track of MagicLoop instances
	var selectedNode: SKNode?
	
	var isRecordingPosition: Bool = false
	var isRecordingScale: Bool = false
	var isRecordingRotation: Bool = false
	var isRotating = false
	var initialMousePosition = CGPoint.zero
	var initialRotation: CGFloat = 0.0
	var anchorOffset = CGPoint.zero
	
	
	private var isExporting = false
	private var exportFrame: CGRect = CGRect(x: 0, y: 0, width: 1024, height: 1024) // Set to desired frame
	private var selectedDirectory: URL?
	var record = false
	private var currentFrameExport: Int = 0
    private var currentFrame: Int = 0
	var counter: Int = 0
	var recordingNumber = 0
	var totalFrames: Int=60*5
	var targetFps: Int = 30
	var loopTime:TimeInterval = TimeInterval(1)
	var rectangle:SKShapeNode = SKShapeNode()
	var lastFrameExportTime = TimeInterval()
	var exportTime = TimeInterval()
	var frames:[CGImage] = []
	private var audioPlayer: AVAudioPlayer?
	var midiClient = MIDIClientRef()
	var midiInputPort = MIDIPortRef()
	var midiEndpoint = MIDIEndpointRef()
	var midiOutputSource = MIDIEndpointRef()
	var midiDestination = MIDIEndpointRef()
	
	var brush = CGPoint(x: 0.5, y: 0.5)
	var maskPosition = CGPoint(x: 0.5, y: 0.5)
	var brushRotation: CGFloat = 0
	var brushScaleX: Double = 0.3
	var brushScaleY: Double = 0.3
	var brushLife: Double = 0.1
	var brushScale = 0.5
	var brushZoom = CGPoint(x: 1, y:1)
	var frequency: Double = 0.2
	var wigglePosition = CGPoint()
	var wiggleScale = CGVector(dx:0.5, dy: 0.5)
	var wiggleFrequency = CGVector(dx:1.0, dy: 1.0)
	var depthCounter = 0.0
//	var mode:UInt8 = 8
	var rotationSpeed = 1.0
	var red = 1.0
	var green = 1.0
	var blue = 1.0
	var brushRed = 1.0
	var brushGreen = 1.0
	var brushBlue = 1.0
    var debugLabel = SKLabelNode()
    var transformOriginal = TransformObject()
    var transformCurrent = TransformObject()
	override func didMove(to view: SKView) {
		super.didMove(to: view)
		backgroundColor = NSColor(white: 0.1, alpha: 1)
		backgroundColor = .white
		registerForDragAndDrop()
		centerExportFrame()
		physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: view.bounds.width, height: view.bounds.height), center: CGPoint(x: view.bounds.width/2, y: view.bounds.height/2))
		physicsWorld.contactDelegate = self
		let floor = SKShapeNode(rect: CGRect(width: 100, height: 100))
		floor.fillColor = .cyan
		floor.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 1000, height: 100))
		floor.physicsBody?.isDynamic = false
		floor.position.x = view.bounds.width/2
		floor.position.y = view.bounds.height/2
		brush.x = frame.width/2
		brush.y = frame.height/2
		//		addChild(floor)
        
//        let openPanel = NSOpenPanel()
//        openPanel.canChooseFiles = false
//        openPanel.canChooseDirectories = true
//        openPanel.allowsMultipleSelection = false
//        openPanel.begin { (result) in
//            if result == .OK, let url = openPanel.url {
//                // Use the selected directory URL
//                self.presetDirectoryPath = url
//                self.loadSequencesFromPresetFolder()
//            }
//        }

       loadSequencesFromPresetFolder()
        debugLabel = SKLabelNode(text: "hello")
        debugLabel.fontName = "Avenir"
        debugLabel.fontSize = 18
        debugLabel.numberOfLines = 0  // Important for multi-line labels
        debugLabel.position = CGPoint(x: frame.minX + 20, y: frame.minY + 40)
        debugLabel.horizontalAlignmentMode = .left
        debugLabel.verticalAlignmentMode = .bottom
       
       
        debugLabel.fontColor = .gray
        debugLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(debugLabel)
	}
	override func didChangeSize(_ oldSize: CGSize) {
		super.didChangeSize(oldSize)
		brush.x = frame.width/2
		brush.y = frame.height/2
		// Adjust the size of the physics body's bounding box to match the new scene size
		physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
		// You may need to reconfigure the physics body or perform additional operations as needed
		//		centerExportFrame()
	}
	
	//MARK: IMPORT
	func handleDroppedFiles(_ urls: [URL], at location: CGPoint) {
		if urls.count == 1, urls.first?.hasDirectoryPath == true {
			addImageSequence(fromFolder: urls.first!, at: location)
		} else {
			addImageSequence(fromFiles: urls, at: location, settings: self.viewModel)
			addAudioFile(fromFiles: urls)
		}
	}
	
    private func addImageSequence(fromFolder folderURL: URL, at location: CGPoint) {
        let fileManager = FileManager.default
        do {
            // Get the parent directory URL (where the folder is located)
            let parentDirectoryURL = folderURL.deletingLastPathComponent()
            
            // Get the name of the folder (without extension)
            let folderName = folderURL.deletingPathExtension().lastPathComponent
            
            // Construct the expected WAV file URL in the parent directory
            let expectedWavFileName = "\(folderName).wav"
            let wavFileURL = parentDirectoryURL.appendingPathComponent(expectedWavFileName)
            
            // Check if the WAV file actually exists at that path
            var isDirectory: ObjCBool = false
            let wavFileExists = fileManager.fileExists(atPath: wavFileURL.path, isDirectory: &isDirectory) && !isDirectory.boolValue
            
            var audioURL: URL? = nil
            if wavFileExists {
                print("Found WAV file for sequence: \(wavFileURL.path)")
                audioURL = wavFileURL
            } else {
                print("No matching WAV file found at expected location: \(wavFileURL.path)")
            }
            
            // Get image URLs from *inside* the dropped folder
            let allFileUrlsInFolder = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            let imageUrls = allFileUrlsInFolder.filter {
                ["png", "jpg", "jpeg"].contains($0.pathExtension.lowercased())
            }
            
            // Call the function to create MagicLoop, passing the audio URL found in the parent directory
            addImageSequence(fromFiles: imageUrls, at: location, settings: self.viewModel, audioURL: audioURL, addToNumbered: true)
            
        } catch {
            print("Error reading folder contents: \(error)")
        }
    }
    private func addImageSequence(fromFiles urls: [URL], at location: CGPoint, settings: SharedObject, audioURL: URL? = nil, addToNumbered: Bool = false) {
        let sortedImageUrls = urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
        
        var textures: [SKTexture] = []
        for imageUrl in sortedImageUrls {
            let texture = SKTexture(imageNamed: imageUrl.path)
            textures.append(texture)
        }
        
        guard !textures.isEmpty else {
            print("No textures loaded for sequence at \(location). Aborting MagicLoop creation.")
            return
        }
        print("Number of frames loaded:", textures.count)

        let magicLoop = MagicLoop(textures: textures, position: location, settings: viewModel, audioURL: audioURL)
        
        self.selectedBrush = magicLoop
        self.lastDraggedNode = magicLoop
        magicLoop.trueScale = CGPoint(x: 0.5, y: 0.5)
        addChild(magicLoop)
        magicLoops.append(magicLoop)
        depthCounter += 1
        magicLoop.zPosition = depthCounter

        // NEW: Add to magicLoopsNumbered if needed
        if addToNumbered {
            magicLoopsNumbered.append(magicLoop)
        }
    }
    func loadSequencesFromPresetFolder() {
        guard FileManager.default.fileExists(atPath: presetDirectoryPath.path) else {
            print("Directory does not exist: \(presetDirectoryPath)")
            return
        }

        do {
            let folderContents = try FileManager.default.contentsOfDirectory(
                at: presetDirectoryPath,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            var i: CGFloat = 0
            let clipHeight: CGFloat = 256
            
            for folderURL in folderContents where folderURL.hasDirectoryPath {
                let yPos = i * clipHeight + self.size.height-128
                let xPos = 100.0
                let newPosition = CGPoint(x: xPos, y: yPos)
                
                addImageSequence(fromFolder: folderURL, at: newPosition)
                i += 1
            }
        } catch {
            print("Error loading presets: \(error.localizedDescription)")
        }
    }
	//MARK: PAINT
	func paint(){
		guard let selected_brush = selectedBrush
		else{
			return
		}
		let newLoop = selected_brush.duplicate(at: wigglePosition)
		addChild(newLoop)
		depthCounter += 1
		newLoop.zPosition = depthCounter//
		selected_brush.zPosition = depthCounter + 1
		newLoop.xScale = selected_brush.xScale
		newLoop.yScale = selected_brush.yScale
		newLoop.run(SKAction.sequence([
			//			SKAction.scale(to: b.xScale*0.8, duration: CGFloat.random(in:0.3...0.4)),
			//			SKAction.scale(to: map(value: sin(time), fromLow: -1, fromHigh: 1, toLow: b.xScale*0.5, toHigh: b.xScale) , duration: CGFloat.random(in:0.3...0.5)),
			//			SKAction.scaleX(to: selected_brush.xScale, duration: 0.2),
			//			SKAction.scaleY(to: selected_brush.yScale, duration: 0.2),
			SKAction.wait(forDuration: brushLife*10),
//			SKAction.run {
//				//			   newLoop.physicsBody?.isDynamic = true
//				newLoop.freeze=true
//				//			   											shape.fillColor = SKColor.white
//			},
			SKAction.wait(forDuration: brushLife*10),
			//		   SKAction.wait(forDuration: 5, withRange: 5),
			//			SKAction.fadeOut(withDuration: brushLife*30),
			SKAction.scale(to: 0, duration: brushLife*10),
			//										 SKAction.fadeOut(withDuration: 2.05),
			SKAction.removeFromParent()
		]))
		//		newLoop.offset = selected_brush.playhead * 0.1//CGFloat(counter)/10
		newLoop.freeze = false
//		newLoop.frameSkip = -1
		//		if Double.random(in: 0...1)>0.9{
		//			newLoop.freeze = false
		//		}
		magicLoops.append(newLoop)
		//		newLoop.physicsBody?.isDynamic = false
	}
	//MARK: UPDATE
	override func update(_ currentTime: TimeInterval) {
        currentFrame += 1
        currentFrame = currentFrame % totalFrames
        let delta:Double = currentTime - prevTime
        time += delta
        prevTime = currentTime
        //MARK: HELP TEXT
        debugLabel.text = "F: select and move\nR: record\n\nC - record transformation\n; - echo\n frame:\(currentFrame) / \(totalFrames)"
        
		wigglePosition = CGPoint(x: brush.x+cos(currentTime*wiggleFrequency.dx)*frame.width/2*wiggleScale.dx, y: brush.y+sin(currentTime*wiggleFrequency.dy)*frame.height/2*wiggleScale.dy)
//		selectedBrush?.position = wigglePosition
//		selectedBrush?.trueScale.x = brushScaleX*brushScale//*map(value: sin(brushScaleX*currentTime*Double.tau), fromLow: -1, fromHigh: 1, toLow: 0.5, toHigh: 1)
//		selectedBrush?.trueScale.y = brushScaleY*brushScale//*map(value: sin(brushScaleY*currentTime*Double.tau), fromLow: -1, fromHigh: 1, toLow: 0.5, toHigh: 1)
//		selectedBrush?.zRotation = -currentTime*rotationSpeed//brushRotation
		selectedBrush?.maskCenter.vectorFloat2Value = vector_float2(Float(maskPosition.x), Float(maskPosition.y))
		selectedBrush?.zoom.vectorFloat2Value = vector_float2(Float(brushZoom.x), Float(brushZoom.y))
		if isPainting{
			counter += 1
			if counter > Int(frequency*127) {
				paint()
				counter = 0
			}
		}
		
		if duplicateKeyPressed {
			duplicateCounter += 1
			if duplicateCounter > 5 {
				duplicateCounter = 0
				duplicateLastDraggedNode()
			}
			
		}
		//MARK: RECORD
		if isRecordingPosition {
			if let selectedLoop = selectedNode as? MagicLoop {
				let targetFrame = (selectedLoop.currentFrame+1)%selectedLoop.totalFrames
				//				let targetFrame = Int(floor(selectedLoop.playhead * Double(selectedLoop.textures.count))+1)%selectedLoop.textures.count
				//				print(targetFrame)
				selectedLoop.positionRecord[targetFrame].x = mousePosition.x - selectedLoop.truePosition.x
				selectedLoop.positionRecord[targetFrame].y = mousePosition.y - selectedLoop.truePosition.y
			}
		}
		if isRecordingScale {
			if let selectedLoop = selectedNode as? MagicLoop {
				//				let targetFrame = Int(selectedLoop.playhead * Double(selectedLoop.textures.count)+1)%selectedLoop.textures.count
				let targetFrame = (selectedLoop.currentFrame+1)%selectedLoop.totalFrames
				let targetXScale = -(selectedLoop.truePosition.x - mousePosition.x) / selectedLoop.spriteNode.frame.width * 2
				let targetYScale = (selectedLoop.truePosition.y - mousePosition.y) / selectedLoop.spriteNode.frame.height * 2
				selectedLoop.scaleRecord[targetFrame].x = targetXScale - selectedLoop.trueScale.x
				selectedLoop.scaleRecord[targetFrame].y = targetYScale - selectedLoop.trueScale.y
			}
		}
		if isRecordingRotation {
			if let selectedLoop = selectedNode as? MagicLoop {
				//				let targetFrame = Int(selectedLoop.playhead * Double(selectedLoop.textures.count)+1)%selectedLoop.textures.count
				let targetFrame = (selectedLoop.currentFrame+1)%selectedLoop.totalFrames
				let deltaX = mousePosition.x - selectedLoop.position.x
				let deltaY = mousePosition.y - selectedLoop.position.y
				let angle = atan2(deltaY, deltaX)
				selectedLoop.rotationRecord[targetFrame] = angle
			}
		}
		if isRotating {
			if let selectedLoop = selectedNode as? MagicLoop {
				let deltaX = mousePosition.x - selectedLoop.position.x
				let deltaY = mousePosition.y - selectedLoop.position.y
				let angle = atan2(deltaY, deltaX)
				
				// Update the rotation of the sprite	 node
				selectedLoop.trueRotation = angle
				print(angle)
			}
		}
		
		let touchedNode = self.atPoint(mousePosition)
		if !selectionLock{
			if let draggableNode = (touchedNode as? SKSpriteNode)?.parent as? MagicLoop {
				//			draggingNode = draggableNode
				self.selectedNode = draggableNode
				//				initialPosition = mousePosition
			} else if let draggableNode = touchedNode as? MagicLoop {
				// If the SKSpriteNode is the same node as the ImageSequenceNode
				//			draggingNode = draggableNode
				self.selectedNode = draggableNode
				//				initialPosition = mousePosition
			}
		}
		//		print("selected: \(self.selectedNode)")
		//		touchedNode.zPosition = 1
		//MARK: EXPORT FRAMES
		if record, let selectedDirectory = selectedDirectory {
			
			
			//			saveFrameAsImage(frame: exportFrame, to: selectedDirectory, prompt: prompt, dateTimeString: dateTimeString)
			for magicLoop in magicLoops {
				magicLoop.update(currentTime: exportTime, recording: true)
			}
			exportTime+=loopTime/Double(self.framesToExport)
			//			saveFrameAsImage(to: selectedDirectory, prompt: prompt, dateTimeString: dateTimeString)
			let fullTexture = self.view!.texture(from: self, crop: self.frame)
			guard let fullCGImage = fullTexture?.cgImage() else { return }
			//			let ciImage = CIImage(cgImage: fullCGImage)
			frames.append(fullCGImage)
			print("frame \(currentFrameExport) exported")
			print("export time \(exportTime)")
			currentFrameExport += 1
			self.viewModel.output = "\(currentFrameExport) / \(framesToExport)"
			if(currentFrameExport>framesToExport-1){
				saveFramesAsMovie(to: selectedDirectory, prompt: prompt, dateTimeString: dateTimeString, frames: frames, frameRate: Int(self.viewModel.fpsExport))
				toggleExport()
				currentFrameExport = 0
			}
		}
		else{
			for magicLoop in magicLoops {
				magicLoop.update(currentTime: time)
			}
		}
		// Calculate the position to center the frame horizontally and vertically
		let centerX = self.size.width / 2
		let centerY = self.size.height / 2
		
		// Calculate the origin of the frame based on its size
		let frameOriginX = centerX + exportFrame.size.width / 2
		let frameOriginY = centerY + exportFrame.size.height / 2
		//		exportFrame.=size.width+256
		//		exportFrame.y=size.height+256
		// Update the exportFrame with the centered origin
		exportFrame.origin = CGPoint(x: frameOriginX, y: frameOriginY)
	}
	
	
	private func centerExportFrame() {
		guard let view = self.view else { return }
		let viewWidth = view.bounds.width
		let viewHeight = view.bounds.height
		
		// Calculate the new origin to keep exportFrame centered
		let x = (viewWidth - exportFrame.width) / 2
		let y = (viewHeight - exportFrame.height) / 2
		
		// Update exportFrame's origin to the new centered position
		//		exportFrame.origin = CGPoint(x: x, y: y)
		rectangle.position = CGPoint(x: x, y: y)
	}
	//MARK: SAVE FRAME
	
	private func saveFrameAsImage(to directoryURL: URL, prompt: String, dateTimeString: String) {
		//			let dirName = String(format: "\(prompt)_%03d", recordingNumber)
		let dirName = "\(prompt)_\(dateTimeString)"//String(format: "\(prompt)_%03d", recordingNumber)
		let sequenceFolder = directoryURL.appendingPathComponent(dirName)
		
		do {
			try FileManager.default.createDirectory(at: sequenceFolder, withIntermediateDirectories: true, attributes: nil)
		} catch {
			print("Failed to create directory: \(error)")
			return
		}
		
		let fileName = String(format: "\(prompt)_%03d.png", currentFrameExport)
		let fileURL = sequenceFolder.appendingPathComponent(fileName)
		
		guard let view = self.view else { return }
		
		// Get the content scale factor
		let scaleFactor = view.window?.screen?.backingScaleFactor ?? 1.0
		
		// Scale the crop rectangle for the Retina screen
		let scaledExportFrame = exportFrame.applying(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
		
		// Capture the full view as a texture
		let fullTexture = view.texture(from: self, crop: self.frame)
		guard let fullCGImage = fullTexture?.cgImage() else { return }
		
		// Crop the full image to the scaled export frame
		//			guard let croppedCGImage = fullCGImage.cropping(to: scaledExportFrame) else { return }
		
		let side = 1024*2
		let myFrame:CGRect = CGRect(x: Int(fullCGImage.width)/2-side/2, y: Int(fullCGImage.height)/2-side/2, width: side, height: side)
		//			guard let croppedCGImage = fullCGImage.cropping(to: exportFrame) else { return }
		guard let croppedCGImage = fullCGImage.cropping(to: myFrame) else { return }
		guard let resizedImage = resizeImage(image: croppedCGImage, to: CGSize(width: 512, height: 512)) else { return }
		//			let ciImage = CIImage(cgImage: croppedCGImage)
		//			let ciImage = CIImage(cgImage: resizedImage)
		let ciImage = CIImage(cgImage: fullCGImage)
		let rep = NSCIImageRep(ciImage: ciImage)
		let nsImage = NSImage(size: rep.size)
		nsImage.addRepresentation(rep)
		
		guard let data = nsImage.tiffRepresentation else { return }
		
		do {
			try data.write(to: fileURL)
		} catch {
			print("Failed to save image: \(error)")
		}
	}
	
	//MARK: SAVE MOVIE
	private func saveFramesAsMovie(to directoryURL: URL, prompt: String, dateTimeString: String, frames: [CGImage], frameRate: Int) {
		let fileName = "\(prompt)_\(dateTimeString).mov"
		let fileURL = directoryURL.appendingPathComponent(fileName)
		
		guard let writer = try? AVAssetWriter(outputURL: fileURL, fileType: .mov) else {
			print("Failed to create AVAssetWriter")
			return
		}
		
		let settings = [
			AVVideoCodecKey: AVVideoCodecType.h264,
			AVVideoWidthKey: 1024,
			AVVideoHeightKey: 1024
		] as [String: Any]
		
		let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
		let sourceBufferAttributes = [
			kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB)
		] as [String: Any]
		let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourceBufferAttributes)
		
		writer.add(writerInput)
		writer.startWriting()
		writer.startSession(atSourceTime: .zero)
		
		var frameTime = CMTime(value: 0, timescale: Int32(frameRate))
		let frameDuration = CMTime(value: 1, timescale: Int32(frameRate))
		
		for frame in frames {
			autoreleasepool {
				guard let pixelBuffer = frame.toPixelBuffer() else {
					print("Failed to convert CGImage to CVPixelBuffer")
					return
				}
				while !writerInput.isReadyForMoreMediaData { usleep(10_000) }
				adaptor.append(pixelBuffer, withPresentationTime: frameTime)
				frameTime = CMTimeAdd(frameTime, frameDuration)
			}
		}
		
		writerInput.markAsFinished()
		writer.finishWriting {
			if writer.status == .completed {
				print("Movie file saved successfully at \(fileURL)")
			} else {
				print("Failed to save movie: \(writer.error?.localizedDescription ?? "unknown error")")
			}
		}
	}
	
	private func saveFrameAsImageWithDateTime(to directoryURL: URL, prompt: String) {
		let dateTimeString = getCurrentDateTimeString()
		saveFrameAsImage(to: directoryURL, prompt: prompt, dateTimeString: dateTimeString)
	}
	
	
	//	private func updateScene(with data: String) {
	//		print(data)
	//	}
	
	
	
	private func addAudioFile(fromFiles urls: [URL]) {
		for url in urls {
			if ["mp3", "wav", "m4a", "aac"].contains(url.pathExtension.lowercased()) {
				do {
					audioPlayer = try AVAudioPlayer(contentsOf: url)
					audioPlayer?.prepareToPlay()
					playAudio()
				} catch {
					print("Error loading audio file: \(error)")
				}
			}
		}
	}
	
	//MARK: AUDIO CONTROL
	func playAudio() {
		audioPlayer?.play()
	}
	
	func pauseAudio() {
		audioPlayer?.pause()
	}
	
	func rewindAudio() {
		audioPlayer?.currentTime = 0
	}
	
	private func enableDragging(for node: SKNode) {
		node.isUserInteractionEnabled = true
	}
	
	private func registerForDragAndDrop() {
		self.isUserInteractionEnabled = true
	}
	
	//MARK: MOUSE DOWN
	override func mouseDown(with event: NSEvent) {
		isPressed = true
		let location = event.location(in: self)
		let touchedNode = self.atPoint(location)
		if let draggableNode = (touchedNode as? SKSpriteNode)?.parent as? MagicLoop {
			draggingNode = draggableNode
			initialPosition = location
			self.lastDraggedNode = touchedNode
			self.selectedBrush = draggableNode
		} else if let draggableNode = (touchedNode as? SKShapeNode)?.parent?.parent as? MagicLoop {
			// If the SKSpriteNode is the same node as the ImageSequenceNode
			draggingNode = draggableNode
			initialPosition = location
			self.lastDraggedNode = touchedNode
			self.selectedBrush = draggableNode
		}
		print("Touched: \(touchedNode)")
		print("last: \(self.lastDraggedNode)")
		//		touchedNode.zPosition = 1
		
	}
	//MARK: DRAG
	override func mouseDragged(with event: NSEvent) {
		guard let draggingNodeAny = self.draggingNode else { return }
		if let draggingNode = self.draggingNode as? MagicLoop {
			let location = event.location(in: self)
			let dx = location.x - initialPosition.x
			let dy = location.y - initialPosition.y
			draggingNode.position.x += dx
			draggingNode.position.y += dy
			draggingNode.truePosition.x += dx
			draggingNode.truePosition.y += dy
			
			initialPosition = location
		}
		//		let location = event.location(in: self)
		//		let dx = location.x - initialPosition.x
		//		let dy = location.y - initialPosition.y
		
		//		draggingNode.position.x += dx
		//		draggingNode.position.y += dy
		
		//		initialPosition = location
	}
	//MARK: MOUSE MOVE
	override func mouseMoved(with event: NSEvent) {
		let location = event.location(in: self)
		mousePosition = location
	}
	
	override func mouseUp(with event: NSEvent) {
		isPressed = false
		print("Mouse Up")
		self.lastDraggedNode = self.draggingNode
		self.draggingNode = nil
	}
	
	override func scrollWheel(with event: NSEvent) {
		if let imageNode = lastDraggedNode as? MagicLoop {
			let delta = event.deltaY
			let scale = 1.0 + delta / 100.0
			imageNode.scale(by: CGFloat(scale))
		}
	}
	
	// MARK: KEY UP
	
	
	override func keyUp(with event: NSEvent) {
		if let lastDragged = lastDraggedNode as? MagicLoop {
			
		}
		selectionLock = false
		
		isRecordingScale = false
		if event.keyCode == Keycode.a { //record movement
			isRecordingPosition = false
		}
		else if event.keyCode == Keycode.z {
			isRotating = false
            isRecordingRotation=false
			
		}
		else if  event.keyCode == Keycode.e{
			duplicateKeyPressed = false
		}

	}
    class TransformObject {
        var scaleChange: CGPoint
        var positionChange: CGPoint
        var rotationChange: CGFloat
        var offsetChange: CGFloat
        var startTime: TimeInterval
        var speedChange: CGFloat
        
        init(scale: CGPoint = CGPoint(x: 1.0, y:1.0),
             position: CGPoint = CGPoint(x: 1.0, y:1.0),
             rotation: CGFloat = 0.0,
             offset: CGFloat = 0.0,
             startTime: TimeInterval = 0.0,
             speed: CGFloat = 1.0) {
            self.scaleChange = scale
            self.positionChange = position
            self.rotationChange = rotation
            self.offsetChange = offset
            self.startTime = startTime
            self.speedChange = speed
        }
    }
	// MARK: KEY DOWN
    func moveSelectedLoop(dx: CGFloat, dy: CGFloat) {
        guard let selectedLoop = selectedBrush as? MagicLoop else { return }
        let target = CGPoint(
            x: (selectedBrush?.truePosition.x)! + dx,
            y: (selectedBrush?.truePosition.y)! + dy
        )

//        let action = SKAction.move(to: target, duration: 0.151)
//        action.timingMode = .easeInEaseOut
//        selectedBrush?.run(action){
            
            selectedLoop.truePosition = target
//        }
    }
	override func keyDown(with event: NSEvent) {
//        let moveDist:CGFloat = (selectedBrush?.trueScale.x ?? 1)*512
        let moveDist:CGFloat = 64
		print("Key pressed: \(event.keyCode)")
		super.keyDown(with: event)
        switch event.keyCode {
        case Keycode.one:
            selectedBrush = magicLoopsNumbered[0]
        case Keycode.two:
            selectedBrush = magicLoopsNumbered[1]
        case Keycode.three:
            selectedBrush = magicLoopsNumbered[2]
        case Keycode.four:
            selectedBrush = magicLoopsNumbered[3]
        case Keycode.five:
            selectedBrush = magicLoopsNumbered[4]
        case Keycode.six:
            selectedBrush = magicLoopsNumbered[5]
        case Keycode.seven:
            selectedBrush = magicLoopsNumbered[6]
        case Keycode.eight:
            selectedBrush = magicLoopsNumbered[7]
        case Keycode.nine:
            selectedBrush = magicLoopsNumbered[8]
        default:
            break
        }
        print(selectedBrush)
        guard let selectedLoop = selectedBrush as? MagicLoop else { return }
      
		switch event.keyCode {
            
                
        case Keycode.h:
            moveSelectedLoop(dx: -moveDist, dy: 0)
        case Keycode.l:
            moveSelectedLoop(dx:  moveDist, dy: 0)
        case Keycode.k:
            moveSelectedLoop(dx: 0, dy:  moveDist)
        case Keycode.j:
            moveSelectedLoop(dx: 0, dy: -moveDist)

       

		case Keycode.i:
			let targetColor: SKColor = isBlack ? .white : .black
			let colorize = SKAction.colorize(with: targetColor, colorBlendFactor: 1.0, duration: 0.2)
			self.run(colorize)
			isBlack.toggle()  // Flip the state
					
		case Keycode.comma:
			viewModel.toggleConsoleVisibility()
			
			// MARK: DUPLICATE
		case Keycode.e:
			duplicateKeyPressed = true
		case Keycode.d:
//			isPainting = !isPainting
			duplicateLastDraggedNode()
        case Keycode.semicolon:
			createEchoes()
			// duplicateAndRotateAnim()
		case Keycode.u:
			// duplicateAndMoveAnim()
			duplicateAndSliceAnim()
		case Keycode.space: // Spacebar keycode
			removeAllNodes()
			//			addChild(rectangle)
			rectangle.zPosition = 0
			
		case Keycode.p:
			print("toggle export" + String(viewModel.prompt))
			toggleExport()
			
		case Keycode.escape:

			NSApplication.shared.terminate(self)
		default:
			break
		}
		
		selectionLock = false
		
	//MARK: MODES
		switch event.keyCode {
        
        case Keycode.r:
            editorMode = Modes.record
        case Keycode.f:
            editorMode = Modes.drag
        case Keycode.c:
            if editorMode == Modes.writeChange {
                editorMode = Modes.drag
                transformCurrent.positionChange = CGPoint(x: selectedBrush!.truePosition.x-transformOriginal.positionChange.x,
                                                    y:  selectedBrush!.truePosition.y-transformOriginal.positionChange.y)
                transformCurrent.scaleChange = CGPoint(x: selectedBrush!.trueScale.x-transformOriginal.scaleChange.x,
                                                    y:  selectedBrush!.trueScale.y-transformOriginal.scaleChange.y)
            } else if editorMode == Modes.drag{
                transformOriginal.positionChange = selectedBrush!.truePosition
                transformOriginal.scaleChange = selectedBrush!.trueScale
                editorMode = Modes.writeChange
            }
            
        
        case Keycode.q:
            selectedLoop.restartPlayback()
//            selectedLoop.playSound()
// MARK: TOGGLE OVERLAY
        case Keycode.tab://50: // ` ~
            selectedLoop.toggleDebugOverlay()
            print("!!")
// MARK: RECORD MOVEMENT
		case Keycode.a:
			isRecordingPosition = true
			selectionLock = true
			
// MARK: ROTATION
        case (Keycode.z):
            if(editorMode == Modes.record){
                selectionLock = true
                isRecordingRotation = true
                initialMousePosition = mousePosition
            }
            else if(editorMode==Modes.drag){
                selectionLock = true
                isRotating = true
            }
// MARK: SCALE
		case Keycode.s:
            if(editorMode == Modes.drag || editorMode == Modes.writeChange){
                if let lastDragged = lastDraggedNode as? MagicLoop {
                    lastDragged.physicsBody?.isDynamic = false
                }
                selectionLock = true
                let targetXScale = -(selectedLoop.truePosition.x - mousePosition.x) / selectedLoop.spriteNode.frame.width * 2
                let targetYScale = (selectedLoop.truePosition.y - mousePosition.y) / selectedLoop.spriteNode.frame.height * 2
                selectedLoop.trueScale.x = targetXScale
                selectedLoop.trueScale.y = targetYScale
                //MARK: RECORD SCALE
            }
            else if(editorMode == Modes.record){
                isRecordingScale = true
                selectionLock = true
            }
			
// MARK: CIRCLE MASK SIZE
		case Keycode.m:
			let deltaX = selectedLoop.truePosition.x - mousePosition.x
			let deltaY = selectedLoop.truePosition.y - mousePosition.y
			let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
			let scaledDistance = distance / (selectedLoop.spriteNode.frame.width * selectedLoop.trueScale.x)
			selectedLoop.maskRadius.floatValue = Float(scaledDistance)
			
// MARK: CIRCLE MASK FUZZINESS
        case Keycode.m:
			let deltaX = selectedLoop.truePosition.x - mousePosition.x
			let deltaY = selectedLoop.truePosition.y - mousePosition.y
			let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
			let scaledDistance = distance / (selectedLoop.spriteNode.frame.width * selectedLoop.trueScale.x)
			selectedLoop.fuzziness.floatValue = Float(scaledDistance)
			
// MARK: CIRCLE MASK CENTER
		case Keycode.m:
			let deltaX = selectedLoop.truePosition.x - mousePosition.x
			let deltaY = selectedLoop.truePosition.y - mousePosition.y
			let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
			let divider = selectedLoop.spriteNode.frame.width * selectedLoop.trueScale.x
			let scaledDistance = distance / (selectedLoop.spriteNode.frame.width * selectedLoop.trueScale.x)
			selectedLoop.maskCenter.vectorFloat2Value = vector_float2(Float(0.5 - deltaX / divider), Float(0.5 - deltaY / divider))
			print(selectedLoop.maskCenter.vectorFloat2Value)
			
// MARK: SWITCH CHANNEL
        case Keycode.y:
			selectedLoop.switchChannel()
			
// MARK: FIT LOOP TO TOTAL TIME
		case Keycode.n:
			selectedLoop.loopTimeMultiplier = 1
			selectedLoop.targetDelta = loopTime / Double(selectedLoop.textures.count)
			
// MARK: PLAYBACK
		case Keycode.equals:
			selectedLoop.targetDelta *= 0.5
		case Keycode.minus:
            selectedLoop.targetDelta *= 2.0
        case Keycode.minus:
            if(selectedLoop.loopTimeMultiplier<1){
                selectedLoop.loopTimeMultiplier = 1
            } else{
                
                selectedLoop.loopTimeMultiplier += 1
            }
			selectedLoop.targetDelta = loopTime / Double(selectedLoop.textures.count) * selectedLoop.loopTimeMultiplier
		
        case Keycode.equals:
            if(selectedLoop.loopTimeMultiplier>1){
                selectedLoop.loopTimeMultiplier -= 1
            }
            else{
                selectedLoop.loopTimeMultiplier *= 0.9;
            }
            selectedLoop.targetDelta = loopTime / Double(selectedLoop.textures.count) * selectedLoop.loopTimeMultiplier

			// MARK: STEP BACK
		case Keycode.leftBracket:
			selectedLoop.offset -= selectedLoop.loopDuration * 0.25
			
			// MARK: STEP FORWARD
		case Keycode.rightBracket:
			selectedLoop.offset += selectedLoop.loopDuration * 0.25
			
			// MARK: REVERSE
//		case Keycode.h:
//			selectedLoop.reversePlayback()
			
			// MARK: SCALE PROPORTIONALLY
//		case Keycode.f:
//			selectedLoop.scale(by: max(-(selectedLoop.position.x - mousePosition.x) / selectedLoop.spriteNode.frame.width * 2, (selectedLoop.position.y - mousePosition.y) / selectedLoop.spriteNode.frame.height * 2))
			
// MARK: BLENDING MODES
		
//		case Keycode.two:
//			selectedLoop.spriteNode.blendMode = .add
//		case Keycode.three:
//			selectedLoop.spriteNode.blendMode = .subtract
//		case Keycode.four:
//			selectedLoop.spriteNode.blendMode = .multiply
//		case Keycode.five:
//			selectedLoop.spriteNode.blendMode = .multiplyX2
//		case Keycode.six:
//			selectedLoop.spriteNode.blendMode = .screen
//		case Keycode.seven:
//			selectedLoop.spriteNode.blendMode = .replace
//		case Keycode.eight:
//			selectedLoop.spriteNode.blendMode = .multiplyAlpha
//		case Keycode.nine:
//			selectedLoop.spriteNode.blendMode = .alpha
			
// MARK: DELETE LOOP
		case Keycode.x:
			selectedLoop.removeFromParent()
			if let index = magicLoops.firstIndex(of: selectedLoop) {
				magicLoops.remove(at: index)
			}

			//MARK: time
			case Keycode.zero: //
				if selectedLoop.loopTimeMultiplier > 1 {
					selectedLoop.loopTimeMultiplier -= 1
				} else {
					selectedLoop.loopTimeMultiplier /= 2
				}
				selectedLoop.targetDelta = loopTime / Double(selectedLoop.textures.count) * selectedLoop.loopTimeMultiplier
				print("1")
				
        
		default:
			break
		}
	}
	
	func deleteLastDraggedNode() {
		guard let lastNode = self.lastDraggedNode else { return }
		lastNode.removeFromParent()
		if let index = magicLoops.firstIndex(of: lastNode as! MagicLoop) {
			magicLoops.remove(at: index)
		}
		self.lastDraggedNode = nil
	}
	
	func removeAllNodes() {
		self.removeAllChildren()
		magicLoops.removeAll() // Clear the magicLoops list
	}
	
	private func getCurrentDateTimeString() -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyyMMdd_HHmm"
		return formatter.string(from: Date())
	}
	
	//MARK: TOGGLE EXPORT
	private func toggleExport() {
		if isExporting {
			rectangle.isHidden = false
			exportTime = 0
			recordingNumber += 1
			isExporting = false
			record = false
			print("Export stopped")
		} else {
			if selectedDirectory == nil {
				selectDirectory()
			} else {
				//				let dateFormatter = DateFormatter()
				//				dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
				self.framesToExport = Int(viewModel.fpsExport*self.loopTime)
				dateTimeString = getCurrentDateTimeString()//dateFormatter.string(from: Date())
				print(dateTimeString)
				self.frames = []
				rectangle.isHidden = true
				currentFrameExport = 0
				isExporting = true
				record = true
				print("Export started")
			}
		}
	}
	
	private func selectDirectory() {
		let openPanel = NSOpenPanel()
		openPanel.canChooseFiles = false
		openPanel.canChooseDirectories = true
		openPanel.allowsMultipleSelection = false
		openPanel.begin { [weak self] result in
			if result == .OK {
				if let url = openPanel.url {
					self?.selectedDirectory = url
					//					self?.isExporting = true
					//					self?.record = true
					//					print("Export started")
					self?.toggleExport()
				}
			}
		}
	}
	
	
	
	//MARK: REPETITION
	func createEchoes(){
		guard let lastNode = selectedBrush else { return }
		if let lastLoop = lastNode as? MagicLoop {
			for i in 0...steps{
				let fractC = Double(i)/Double(steps)
				//				let newLoop = lastLoop.duplicate(at: mousePosition)
//				let newLoop = lastLoop.duplicate(at: CGPoint(x: self.frame.width/2, y: self.frame.height/2))
                let newLoop = lastLoop.duplicate(at: CGPoint(x: (selectedBrush?.truePosition.x)!, y: (selectedBrush?.truePosition.y)!))
				//				newLoop.trueRotation = fractionOfCircumference*CGFloat.tau
				for j in 0...(newLoop.textures.count-1) {
					let a2 = Double(j)/Double(newLoop.textures.count-1)
					let s = Double(sin(a2*Double.tau)*0.1)
					let dist = self.frame.height/10
					//					newLoop.positionRecord[j] = CGPoint(x: cos((a2+fractC)*Double.tau)*dist*s, y: sin((a2+fractC)*Double.tau)*dist*s)
					//					newLoop.positionRecord[j] = CGPoint(x: 0, y: sin((a2+fractC)*Double.tau*2)*dist)
					//					newLoop.rotationRecord[j]=sin(a2*CGFloat.tau)*CGFloat(self.angle)*a
					//					newLoop.rotationRecord[j]=CGFloat(EASE.easeInOutCubic(Float(a2)) * Float.tau)
					//					newLoop.rotationRecord[j]=sin(CGFloat(a2)*CGFloat.tau+fractC*CGFloat.tau)*CGFloat.tau/8
					//						newLoop.scaleRecord[j] = CGPoint(x: s, y: s)
				}
				let addedScale:CGFloat = fractC*1.0
                newLoop.trueScale = CGPoint(x:lastLoop.trueScale.x + transformCurrent.scaleChange.x*CGFloat(i), y:lastLoop.trueScale.y+transformCurrent.scaleChange.y*CGFloat(i))
                newLoop.truePosition.x = newLoop.truePosition.x+(transformCurrent.positionChange.x)*CGFloat(i)
                newLoop.truePosition.y = newLoop.truePosition.y+(transformCurrent.positionChange.y)*CGFloat(i)
				//				newLoop.maskRadius.floatValue = Float(map(value: fractC, fromLow: 0, fromHigh: 1, toLow: 0.0, toHigh: 0.5))
				newLoop.threshold.floatValue = Float(map(value: fractC, fromLow: 0, fromHigh: 1, toLow: 0.0, toHigh: 1.0))
				newLoop.timeOffset = Double(lastLoop.loopDuration) * fractC*0.01
				newLoop.offset = fractC
				addChild(newLoop)
				newLoop.zPosition = lastNode.zPosition - CGFloat(i)
				magicLoops.append(newLoop)
			}
		}
	}
    //MARK: REVERSE ECHO
    func _createEchoes(){
        guard let lastNode = lastDraggedNode else { return }
        if let lastLoop = lastNode as? MagicLoop {
            for i in 0...steps{
                let fractC = Double(i)/Double(steps)
                //                let newLoop = lastLoop.duplicate(at: mousePosition)
                let newLoop = lastLoop.duplicate(at: CGPoint(x: self.frame.width/2, y: self.frame.height/2))
                //                newLoop.trueRotation = fractionOfCircumference*CGFloat.tau
                for j in 0...(newLoop.textures.count-1) {
                    let a2 = Double(j)/Double(newLoop.textures.count-1)
                    let s = Double(sin(a2*Double.tau)*0.1)
                    let dist = self.frame.height/10
                    //                    newLoop.positionRecord[j] = CGPoint(x: cos((a2+fractC)*Double.tau)*dist*s, y: sin((a2+fractC)*Double.tau)*dist*s)
                    //                    newLoop.positionRecord[j] = CGPoint(x: 0, y: sin((a2+fractC)*Double.tau*2)*dist)
                    //                    newLoop.rotationRecord[j]=sin(a2*CGFloat.tau)*CGFloat(self.angle)*a
                    //                    newLoop.rotationRecord[j]=CGFloat(EASE.easeInOutCubic(Float(a2)) * Float.tau)
                    //                    newLoop.rotationRecord[j]=sin(CGFloat(a2)*CGFloat.tau+fractC*CGFloat.tau)*CGFloat.tau/8
                    //                        newLoop.scaleRecord[j] = CGPoint(x: s, y: s)
                }
                let addedScale:CGFloat = fractC*1.5
                newLoop.trueScale = CGPoint(x:lastLoop.trueScale.x + addedScale, y:lastLoop.trueScale.y+addedScale)
                
                //                newLoop.maskRadius.floatValue = Float(map(value: fractC, fromLow: 0, fromHigh: 1, toLow: 0.0, toHigh: 0.5))
                newLoop.threshold.floatValue = Float(map(value: fractC, fromLow: 0, fromHigh: 1, toLow: 0.0, toHigh: 1.0))
                newLoop.timeOffset = Double(lastLoop.loopDuration) * fractC*0.01
                newLoop.offset = fractC
                addChild(newLoop)
                newLoop.zPosition = lastNode.zPosition - CGFloat(i)
                magicLoops.append(newLoop)
            }
        }
    }
	//MARK: LOTUS ANIMATION
	func duplicateAndRotateAnim() {
		guard let lastNode = lastDraggedNode else { return }
		if let lastLoop = lastNode as? MagicLoop {
			let rings = 9
			for h in 1...rings {
				let a0 = CGFloat(h)/CGFloat(rings)
				let steps_ = steps+h*2-1
				for i in 0...steps_{
					let a = CGFloat(i)/CGFloat(steps_)
					
					//				let newLoop = lastLoop.duplicate(at: mousePosition)
					
					let newLoop = lastLoop.duplicate(at: CGPoint(x: self.frame.width/2, y: self.frame.height/2))
					var dist = self.frame.height * 0.4 * a0
					newLoop.truePosition = CGPoint(x: self.frame.width/2+cos(a*Double.tau)*dist, y: self.frame.height/2+sin(a*Double.tau)*dist)
					
					newLoop.trueRotation = a*CGFloat.tau
					
					//				newLoop.trueRotation = sin(a * CGFloat.pi*2(steps/2))*CGFloat.pi*2
					//				newLoop.trueRotation = newLoop.trueRotation+(1-a*0.5)*CGFloat.tau/24
					//				newLoop.trueRotation = sin(a*CGFloat.tau)*CGFloat.tau/30
					
					dist = self.frame.height/10
					for j in 0...(newLoop.textures.count-1) {
						let a2 = Float(j)/Float(newLoop.textures.count-1)
						let s = CGFloat(sin(a2*Float.tau)*0.1)
						//						newLoop.positionRecord[j] = CGPoint(x: cos(a*Double.tau)*dist*s, y: sin(a*Double.tau)*dist*s)
						//					newLoop.rotationRecord[j]=sin(a2*CGFloat.tau)*CGFloat(self.angle)*a
						//						newLoop.rotationRecord[j]=CGFloat(EASE.easeInOutCubic(a2)*Float.tau)
						//sin(a2*CGFloat.tau+a*CGFloat.tau)*CGFloat(CGFloat.tau/4)
						//						newLoop.scaleRecord[j] = CGPoint(x: s, y: s)
					}
					
					let newScale:CGFloat = -a0*0.5//a * 1.1
					//					newLoop.trueScale = CGPoint(x:lastLoop.trueScale.x*(1-pow(a0, 2)),y:lastLoop.trueScale.y*(1-pow(a0, 2)))
					
					let delayDuration: TimeInterval = a * 3.0 // Example delay of 0.5 seconds
					let delayAction = SKAction.wait(forDuration: delayDuration)
					let scaleXAction = SKAction.scaleX(to: newLoop.trueScale.x, duration: 1)
					scaleXAction.timingFunction = EASE.easeInOutQuad
					let scaleYAction = SKAction.scaleY(to: newLoop.trueScale.y, duration: 1)
					scaleYAction.timingFunction = EASE.easeInOutQuad
					//					newLoop.run(SKAction.group([delayAction, scaleXAction, delayAction, scaleYAction]))
					
					newLoop.maskRadius.floatValue = 0.5
					//					newLoop.fuzziness.floatValue = 0.5//Float(a)
					//				newLoop.targetDelta = loopTime/Double(framesToExport)
					//				newLoop.currentFrame = lastLoop.currentFrame+newLoop.textures.count * i/steps
					//					newLoop.timeOffset = Double(lastLoop.loopDuration) * a0
					newLoop.timeOffset = Double(lastLoop.loopDuration) * a + (Double(lastLoop.loopDuration))*a0
					//					newLoop.timeOffset = a0 *  Double(loopTime)
					//				lastDraggedNode = newLoop
					addChild(newLoop)
					newLoop.zPosition = lastNode.zPosition - CGFloat(i)
					magicLoops.append(newLoop)
				}
			}
		}
	}
	//MARK: SLICE ANIMATION
	func duplicateAndSliceAnim() {
		guard let lastNode = lastDraggedNode else { return }
		var n = 0.0
		let side = Int(sqrt(Double(steps)))
		if let lastLoop = lastNode as? MagicLoop {
			for j in 0...side {
				let y =  CGFloat(j)/CGFloat(side)
				for i in 0...side {
					let x = CGFloat(i)/CGFloat(side)
					n += 1
					let a = CGFloat(n)/CGFloat(steps)
					//				let newLoop = lastLoop.duplicate(at: mousePosition)
					let newLoop = lastLoop.duplicate(at: CGPoint(x: self.frame.width/2, y: self.frame.height/2))
					let dx = x - 0.5
					let dy = y - 0.5
					newLoop.offset = sqrt(dx*dx+dy*dy)
					
					
					newLoop.offset = a/2
					//					newLoop.offset = Double(loopTime) * pow(n / Double(steps), 2)
					//					newLoop.timeOffset =  Double(lastLoop.loopDuration) * newLoop.offset
					newLoop.timeOffset =  Double(loopTime) * newLoop.offset
					//rectangles
					newLoop.params.vectorFloat4Value = vector_float4(Float(side), Float(side), Float(j), Float(i))
					//vertical slices
					//					newLoop.params.vectorFloat4Value = vector_float4(Float(side*side), 1, Float(n), 0)
					
					//horizontal slices
					newLoop.params.vectorFloat4Value = vector_float4(1, Float(side*side), 0, Float(n))
					
					
					addChild(newLoop)
					newLoop.zPosition = lastNode.zPosition - CGFloat(i)
					magicLoops.append(newLoop)
				}
			}
		}
	}
	
	//MARK: GRID ANIMATION
	func duplicateAndMoveAnim() {
		guard let lastNode = lastDraggedNode else { return }
		if let lastLoop = lastNode as? MagicLoop {
			for h in 0...steps {
				let ha =  CGFloat(h)/CGFloat(steps)
				for i in 0...steps {
					let a = CGFloat(i)/CGFloat(steps)
					let newLoop = lastLoop.duplicate(at: mousePosition)
					//				newLoop.trueRotation = sin(a * CGFloat.pi*2(steps/2))*CGFloat.pi*2
					//				newLoop.trueRotation = newLoop.trueRotation+(1-a*0.5)*CGFloat.tau/24
					for j in 0...(newLoop.textures.count-1) {
						let a2 = CGFloat(j)/CGFloat(newLoop.textures.count-1)
						//					newLoop.rotationRecord[j]=sin(a2*CGFloat.tau)*CGFloat.tau/24*a
					}
					//				newLoop.trueScale = CGPoint(x:a+lastLoop.trueScale.x,y:a+lastLoop.trueScale.y)
					newLoop.truePosition = CGPoint(x: a*frame.width, y:ha*frame.width)
					newLoop.currentFrame = lastLoop.currentFrame+newLoop.textures.count * i/steps
					print("-----")
					print(i)
					print(a)
					print("steps: \(steps)")
					print(newLoop.zRotation)
					lastDraggedNode = newLoop
					addChild(newLoop)
					newLoop.zPosition = lastNode.zPosition - CGFloat(i)
					magicLoops.append(newLoop)
				}
			}
		}
	}
	
	//MARK: DUPLICATION FUNCTION
	func duplicateLastDraggedNode() {
		guard let lastNode = selectedBrush else { return }
		if let spriteNode = lastNode as? SKSpriteNode, let texture = spriteNode.texture {
			let newNode = SKSpriteNode(texture: texture)
			newNode.position = mousePosition
            newNode.position = CGPoint(x:selectedBrush?.position.x ?? 0, y:selectedBrush?.position.y ?? 0)
			//			addTransparentBackground(for: newNode)
			addChild(newNode)
			newNode.zPosition = lastNode.zPosition + 1
		} else if let imageNode = lastNode as? MagicLoop {
			let newImageNode = imageNode.duplicate(at: mousePosition)
//            newImageNode.position = CGPoint(x:selectedBrush?.position.x ?? 0, y:selectedBrush?.position.y ?? 0)
            newImageNode.truePosition = lastNode.position
			lastDraggedNode = newImageNode
			selectedBrush = newImageNode
			addChild(newImageNode)
			newImageNode.zPosition = lastNode.zPosition + 1
			newImageNode.offset = imageNode.offset+1.01
            newImageNode.truePosition.x+=transformCurrent.positionChange.x
            newImageNode.truePosition.y+=transformCurrent.positionChange.y
            newImageNode.trueScale.x+=transformCurrent.scaleChange.x
            newImageNode.trueScale.y+=transformCurrent.scaleChange.y
//			newImageNode.currentFrame = imageNode.currentFrame+1
			magicLoops.append(newImageNode) // Add the duplicated node to the list
			depthCounter += 1
			newImageNode.zPosition = depthCounter//
		}
	}
	
	//MARK: SEND TO SERVER
	func processMagicLoopWithControlNet(_ magicLoop:MagicLoop, _ test:Bool = false) {
		//		guard let magicLoop = magicLoop else { return }
		
		var frames = magicLoop.textures.map { texture in
			let cgImage = texture.cgImage
			let size = texture.size()
			let nsImage = NSImage(cgImage: cgImage(), size: NSSize(width: size.width, height: size.height))
			return nsImage
		}
		if test {
			frames = [frames[magicLoop.currentFrame]]
		}
		
		print(self.prompt)
		sendFramesToServer(frames: frames, prompt: self.prompt, steps: self.steps) { generatedFrames in
			DispatchQueue.main.async {
				self.createNewMagicLoop(with: generatedFrames)
			}
		}
	}
	
	
	func sendFramesToServer(frames: [NSImage], prompt: String, steps: Int, completion: @escaping ([NSImage]) -> Void) {
		guard let url = URL(string: "http://localhost:8000/generate") else { return }
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		let boundary = UUID().uuidString
		request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
		
		let body = createMultipartBody(with: frames, boundary: boundary, prompt: prompt, steps: steps)
		request.httpBody = body
		
		// Set timeout interval to 60 seconds (adjust as needed)
		request.timeoutInterval = 60*1000
		
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			guard let data = data, error == nil else {
				print("Error: \(error?.localizedDescription ?? "Unknown error")")
				completion([])
				return
			}
			
			do {
				if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
				   let framesBase64 = jsonResponse["frames"] as? [String] {
					let generatedFrames = framesBase64.compactMap { base64String -> NSImage? in
						if let data = Data(base64Encoded: base64String),
						   let image = NSImage(data: data) {
							return image
						}
						return nil
					}
					completion(generatedFrames)
				}
			} catch {
				print("Error parsing response: \(error)")
				completion([])
			}
		}
		
		task.resume()
	}
	
	func createMultipartBody(with frames: [NSImage], boundary: String, prompt: String, steps: Int) -> Data {
		print(prompt)
		print(steps)
		var body = Data()
		
		// Append prompt and steps as form data
		body.append("--\(boundary)\r\n")
		body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n")
		body.append("\(prompt)\r\n")
		body.append("--\(boundary)\r\n")
		body.append("Content-Disposition: form-data; name=\"steps\"\r\n\r\n")
		body.append("\(steps)\r\n")
		
		for (index, frame) in frames.enumerated() {
			guard let tiffData = frame.tiffRepresentation,
				  let bitmap = NSBitmapImageRep(data: tiffData),
				  let jpegData = bitmap.representation(using: .jpeg, properties: [:]) else { continue }
			
			body.append("--\(boundary)\r\n")
			body.append("Content-Disposition: form-data; name=\"files\"; filename=\"frame\(index).jpg\"\r\n")
			body.append("Content-Type: image/jpeg\r\n\r\n")
			body.append(jpegData)
			body.append("\r\n")
		}
		
		body.append("--\(boundary)--\r\n")
		
		return body
	}
	
	func createNewMagicLoop(with frames: [NSImage]) {
		let textures = frames.map { SKTexture(image: $0) }
		print("Number of textures created: \(textures.count)")
		
		let newMagicLoop = MagicLoop(textures: textures, position: CGPoint(x: self.size.width / 2, y: self.size.height / 2), settings: self.viewModel)
		newMagicLoop.frameSkip = 1
		magicLoops.append(newMagicLoop)
		addChild(newMagicLoop)
	}
}

// Extending Data to append strings
extension Data {
	mutating func append(_ string: String) {
		if let data = string.data(using: .utf8) {
			append(data)
		}
	}
}

extension SKView {
	open override func viewDidMoveToWindow() {
		super.viewDidMoveToWindow()
		window?.acceptsMouseMovedEvents = true
	}
}

public class KeyboardHelper
{
	public static var optionKeyIsDown: Bool
	{
		let flags = NSEvent.modifierFlags
		return flags.contains(.option)
	}
	
	public static var shiftKeyIsDown: Bool
	{
		let flags = NSEvent.modifierFlags
		return flags.contains(.shift)
	}
}

extension CGImage {
	func toPixelBuffer() -> CVPixelBuffer? {
		let width = self.width
		let height = self.height
		let attrs = [
			kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
			kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
		] as CFDictionary
		
		var pixelBuffer: CVPixelBuffer?
		let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
		
		guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
		
		CVPixelBufferLockBaseAddress(buffer, [])
		let data = CVPixelBufferGetBaseAddress(buffer)
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let context = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
		
		context?.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
		CVPixelBufferUnlockBaseAddress(buffer, [])
		
		return buffer
	}
}
