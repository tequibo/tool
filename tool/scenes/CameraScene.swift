import SpriteKit
import AVFoundation
import Cocoa

class CameraScene: SKScene, AVCaptureVideoDataOutputSampleBufferDelegate {
	private var spriteNode: SKSpriteNode?
	private let captureSession = AVCaptureSession()
	private var textureCache: CVMetalTextureCache?
	var model = DeepLabV3_2()
	var spriteNodes = [[SKSpriteNode]]()
	let rows = 55
	let columns = 55
	func createGrid(rows: Int, columns: Int, nodeSize: CGSize) {
			let containerNode = SKNode()
			containerNode.position = CGPoint(x: frame.midX, y: frame.midY)
			containerNode.zPosition=1.0
			addChild(containerNode)
//			let gridWidth = CGFloat(columns) * nodeSize.width
//			let gridHeight = CGFloat(rows) * nodeSize.height
			let startX = -(self.size.width) / 2
			let startY = (self.size.height) / 2
			let distX = self.size.width/CGFloat(columns)
			let distY = self.size.height/CGFloat(rows)
			for row in 0..<rows {
				var rowArray = [SKSpriteNode]()
				for column in 0..<columns {
					let spriteNode = SKSpriteNode(color: .white, size: nodeSize)
					spriteNode.position = CGPoint(
						x: startX + CGFloat(column) * distX,
						y: startY - CGFloat(row) * distY
					)
					spriteNode.zRotation=CGFloat.random(in: -CGFloat.pi...CGFloat.pi)
					containerNode.addChild(spriteNode)
					rowArray.append(spriteNode)
				}
				spriteNodes.append(rowArray)
			}
		}
	override func didMove(to view: SKView) {
		self.setupCamera()
		self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
		self.spriteNode = SKSpriteNode(color: .clear, size: self.size)
		
		if let spriteNode = self.spriteNode {
			self.addChild(spriteNode)
		}
		createGrid(rows: rows, columns: columns, nodeSize: CGSize(width: 10, height: 10))
	}

	private func setupCamera() {
		let videoDevices = getAllVideoCaptureDevices()
		for device in videoDevices {
			print("Device name: \(device)")
		}
		let uniqueID = "8C819767-9875-45EE-A2B4-06C200000001"
		guard let device = AVCaptureDevice(uniqueID: uniqueID) else {
			print("Device not found")
			return
		}
		guard let device = AVCaptureDevice.default(for: .video) else { return }
		guard let input = try? AVCaptureDeviceInput(device: device) else { return }
		captureSession.addInput(input)

		let output = AVCaptureVideoDataOutput()
		output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
		output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
		captureSession.addOutput(output)

		captureSession.startRunning()
	}

	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//		guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
		guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
//		let width = CVPixelBufferGetWidth(pixelBuffer)
//		let height = CVPixelBufferGetHeight(pixelBuffer)
//		print("Width: \(width), Height: \(height)")
		let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//		guard let cropped = resizePixelBuffer(pixelBuffer, cropX: (1920-1080)/2, cropY: 0, cropWidth: 1080, cropHeight: 1080, scaleWidth: 513, scaleHeight: 513) else { return }
		guard let cropped = resizePixelBuffer(pixelBuffer, width: 513, height: 513) else { return }
//		let scale = CGAffineTransform(scaleX: CGFloat(513) / CGFloat(width),
//										 y: CGFloat(513) / CGFloat(height))
//		let resizedImage = ciImage.transformed(by: scale)
//		var newPixelBuffer: CVPixelBuffer?
//		CVPixelBufferCreate(nil, 513, 513, CVPixelBufferGetPixelFormatType(pixelBuffer), nil, &newPixelBuffer)
		let context = CIContext(options: nil)
		guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
		
		let nsImage = NSImage(cgImage: cgImage, size: NSZeroSize)
		
		DispatchQueue.main.async {
			let skTexture = SKTexture(image: nsImage)
			self.spriteNode?.texture = skTexture
		}
		
		
		guard let pred = try?model.prediction(image: cropped) else {
			fatalError("Unexpected runtime error.")
		}
//		let value = pred.semanticPredictions[[0, 0, 1] as [NSNumber]].intValue
		for row in 0..<rows {
			for column in 0..<columns {
				let spriteNode = spriteNodes[row][column]
				let index = [NSNumber(value: 513/rows*row), NSNumber(value: 513/columns*column)]
				let value = pred.semanticPredictions[index].int32Value
				let scaleAction = SKAction.scale(to: CGFloat(value)/2, duration: 0.1)
				spriteNode.run(scaleAction)
//				spriteNode.texture = skTexture
//				spriteNode.xScale = CGFloat(value)/20+0.1
//				spriteNode.yScale = CGFloat(value)/20+0.1
				
			}
		}
//		["background", "aeroplane", "bicycle", "bird", "boat", "bottle", "bus", "car", "cat", "chair", "cow", "diningTable", "dog", "horse", "motorbike", "person", "pottedPlant", "sheep", "sofa", "train", "tvOrMonitor"]

//		print(pred.semanticPredictions)
//		print(pred.semanticPredictionsShapedArray)
//		print(pred.featureNames)
		
		
	}
	override func keyDown(with event: NSEvent) {
		switch event.keyCode {
		case 0x31:
			return
		case 0x35:
			exit(0)
		default:
			print("keyDown: \(event.characters!) keyCode: \(event.keyCode)")
		}
	}
	func getAllVideoCaptureDevices() -> [AVCaptureDevice] {
		let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, AVCaptureDevice.DeviceType.external]
		let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: .video, position: .unspecified)
		return discoverySession.devices
	}
}

