
import SpriteKit
import GameplayKit
import AVFoundation



class GameScene: SKScene {
    private var counter = 0
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    private var brushPos: CGPoint = CGPoint(x:0, y:0)
   
    override func didMove(to view: SKView) {
      

        let captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                  for: .video, position: .unspecified)
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
            captureSession.canAddInput(videoDeviceInput)
        else { return }
        captureSession.addInput(videoDeviceInput)
        
        let photoOutput = AVCapturePhotoOutput()
        guard captureSession.canAddOutput(photoOutput) else { return }
        captureSession.sessionPreset = .photo
        captureSession.addOutput(photoOutput)
        captureSession.commitConfiguration()
        print(captureSession)
        
        
        self.label = self.childNode(withName: "//healthLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.text = "011"
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }

        let w = (self.size.width + self.size.height) * 0.01
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.0)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 0
//            spinnyNode.alpha = 0
//            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 2.5)))
            spinnyNode.run(SKAction.sequence([
//                                                SKAction.fadeIn(withDuration: 0.2),
                                              SKAction.wait(forDuration: 2.5),
//                                              SKAction.resize(toWidth: 0.1, height: 0.1, duration: 1.0),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            self.counter += 1
            let a = CGFloat(self.counter)*0.01
            let radius = CGFloat.random(in:self.size.height*0.3..<self.size.height*0.3+50)
            self.brushPos.x = cos(a)*radius
            self.brushPos.y = sin(a)*radius
            if let n = self.spinnyNode?.copy() as! SKShapeNode? {
    //            n.position = CGPoint(x: CGFloat.random(in:-self.size.width..<self.size.width),
    //                                 y: CGFloat.random(in:-self.size.height..<self.size.height))
                n.position = self.brushPos
                n.xScale=cos(self.alpha)*10.0//CGFloat.random(in:0.1...1.5)
    //            n.strokeColor = SKColor.blue
                n.fillColor = SKColor.white
                n.lineWidth = 0
                self.addChild(n)
            }
        }
       
    }
    
    override func update(_ currentTime: TimeInterval) {
        self.label?.text = "\(counter)"
        // Called before each frame is rendered
    }
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
//            n.strokeColor = SKColor.green
            n.fillColor = SKColor.cyan
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
//            n.strokeColor = SKColor.blue
//            n.fillColor = SKColor.white
            n.fillColor = SKColor.cyan
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
//            n.strokeColor = SKColor.red
//            n.fillColor = SKColor.white
            self.addChild(n)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        self.touchDown(atPoint: event.location(in: self))
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.touchMoved(toPoint: event.location(in: self))
    }
    
    override func mouseUp(with event: NSEvent) {
        self.touchUp(atPoint: event.location(in: self))
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 0x31:
            if let label = self.label {
                label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
            }
        case 0x35:
            exit(0)
        default:
            print("keyDown: \(event.characters!) keyCode: \(event.keyCode)")
        }
    }
    
    

}
