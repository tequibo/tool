import SpriteKit

class MagicLoop: SKNode {
	private var lastFrameTime:CGFloat = 0
	public var spriteNode: SKSpriteNode
	public var textures: [SKTexture]
	public var animationSpeed: CGFloat = 1.0
	public var FPS: Int = 30
	public var currentFrame: Int = 0
	private var frameCounter: Int = 0
	public var frameSkip: Int = -1
	public var updateFrameSkip: Int = 1
	public var isReversed: Bool = false
	
	private var debugOverlay: SKNode? // Node to hold the debug overlay elements
	private var fpsLabel: SKLabelNode?
	private var timeLabel: SKLabelNode?
	private var currentFrameLabel: SKLabelNode?
	private var progressBar: SKShapeNode?
	private var outline: SKShapeNode?
	
	// Properties for FPS calculation
	private var lastUpdateTime: TimeInterval = 0
	private var frameCount: Int = 0
	private var fps: Double = 0
	public var targetFps: Double = 60
	// Mask properties
	private var maskNode: SKShapeNode?
	private var cropNode: SKCropNode
	private var isMasked: Bool = false
	public var positionRecord:[CGPoint] = []
	public var scaleRecord:[CGPoint] = []
	public var rotationRecord:[CGFloat] = []
	public var truePosition:CGPoint = CGPoint()
	public var trueScale:CGPoint = CGPoint()
	public var trueRotation:CGFloat = CGFloat()
	
	
	
	public var targetDelta:CGFloat = 0.03
	public var targetTotalFrames:Int = 0
	public var totalFrames:Int = 0
	var delta:TimeInterval = 0.0
	var lastChangedFrameTime:TimeInterval = 0.0
	var playhead:TimeInterval = 0
	public var timeOffset = TimeInterval()
	public var offset = 0.0
	var loopTimeMultiplier: Double = 1
	var loopDuration:TimeInterval = 0
	public var maskRadius:SKUniform = SKUniform(name: "u_radius", float: 1.5)
	public var fuzziness:SKUniform = SKUniform(name: "u_fuzziness", float: 0.0)
	public var threshold:SKUniform = SKUniform(name: "u_threshold", float: 0.0)
	public var maskCenter:SKUniform = SKUniform(name: "u_center", vectorFloat2: vector_float2(0.5, 0.5))
	public var zoom:SKUniform = SKUniform(name: "u_zoom", vectorFloat2: vector_float2(1, 1))
	public var channels:SKUniform = SKUniform(name: "u_channels", vectorFloat4: vector_float4(1, 1, 1, 1))
	public var params:SKUniform = SKUniform(name: "u_params", vectorFloat4: vector_float4(1, 1, 0, 0))
	public var texture:SKUniform = SKUniform(name: "u_mask_texture", texture: SKTexture(imageNamed: "mask_texture"))
	public var freeze = false
	
	var channelSwitches:[vector_float4] = [vector_float4(1, 1, 1, 1),
										   vector_float4(1, 0, 0, 1),
										   vector_float4(0, 1, 0, 1),
										   vector_float4(0, 0, 1, 1)]
	var channelSwitchIndex:Int = 0

	public var primer:Bool = false
	public var globalSettings:SharedObject
	
	init(textures: [SKTexture], position: CGPoint, settings: SharedObject) {
		self.globalSettings = settings
		
		self.textures = textures
		self.spriteNode = SKSpriteNode(texture: textures.first)
		self.cropNode = SKCropNode()
		if(textures.count == 1){
			self.targetTotalFrames = 60
			self.totalFrames = 60
		}
		else{
			self.targetTotalFrames = textures.count
			self.totalFrames = textures.count
		}
		self.positionRecord = Array(repeating: CGPoint(), count: self.totalFrames)
		self.scaleRecord = Array(repeating: CGPoint(), count: self.totalFrames)
		self.rotationRecord = Array(repeating: CGFloat(), count: self.totalFrames)
		self.targetDelta=1.0/30
		super.init()
//		self.spriteNode.blendMode = .add
		self.position = position
		addChild(spriteNode)
		let negativeShader = SKShader(source: "void main() { " +
			"    gl_FragColor = vec4(1.0 - SKDefaultShading().rgb, SKDefaultShading().a); " +
			"}")
		let circleMaskShader = SKShader(source: """
		void main() {
			vec2 uv = v_tex_coord;
			vec2 center = vec2(0.5, 0.5);
			float radius = u_radius;
			float dist = distance(uv, center);

			vec4 color = SKDefaultShading();
			if (dist > radius) {
				color.a = 0.0;
				color.rgb = vec3(.0,.0,.0);
			}
			color = color*u_channels;
			gl_FragColor = color;
		}
		""")
		let uniforms: [SKUniform] = [
			maskRadius,
			channels,
			params,
			fuzziness,
			maskCenter,
			texture,
			threshold,
			zoom
//			SKUniform(name: "u_strength", float: 2),
//			SKUniform(name: "u_density", float: 100),
//			SKUniform(name: "u_center", point: CGPoint(x: 0.68, y: 0.33)),
//			SKUniform(name: "u_color", color: SKColor(red: 0, green: 0.5, blue: 0, alpha: 1))
		]

		let slicer =  SKShader(fromFile: "mask", uniforms: uniforms)

		circleMaskShader.uniforms = [
			maskRadius,
			channels,
			params,
			fuzziness
		]
		spriteNode.shader = circleMaskShader


//		self.xScale = 0.5
//		self.yScale = 0.5
//		self.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: textures[0].size().width, height: textures[0].size().height))
//		self.physicsBody!.contactTestBitMask = 0b0001
//		self.physicsBody!.isDynamic = false
		self.truePosition = self.position
		self.trueScale = CGPoint(x: self.xScale, y: self.yScale)
		createDebugOverlay()
//		
//		let sourcePositions: [float2] = [
//			float2(0, 1),   float2(0.5, 1),   float2(1, 1),
//			float2(0, 0.5), float2(0.5, 0.5), float2(1, 0.5),
//			float2(0, 0),   float2(0.5, 0),   float2(1, 0)
//		]
//		
//		let destinationPositions: [float2] = [
//			float2(-0.25, 1.5), float2(0.5, 1.75), float2(1.25, 1.5),
//			float2(0.25, 0.5),   float2(0.5, 0.5),   float2(0.75, 0.5),
//			float2(-0.25, -0.5),  float2(0.5, -0.75),  float2(1.25, -0.5)
//		]
//		
//		let warpGeometryGrid = SKWarpGeometryGrid(columns: 2,
//												  rows: 2,
//												  sourcePositions: sourcePositions,
//												  destinationPositions: destinationPositions)
//		
////		let sprite = SKSpriteNode()
//		let warpGeometryGridNoWarp = SKWarpGeometryGrid(columns: 2, rows: 2)
//		self.spriteNode.warpGeometry = warpGeometryGridNoWarp
//		let warpAction = SKAction.warp(to: warpGeometryGrid,duration: 0.5)
//		spriteNode.run(warpAction!)
		// Define the action with easing
		let scaleUpAction = SKAction.scale(to: 1, duration: 0.2)
		scaleUpAction.timingMode = .easeOut // Apply easing

		// Run the action
		spriteNode.scale(to: CGSize(width: 0.0, height: 0.0))
		spriteNode.run(scaleUpAction)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// Method to create a circular mask
	public func switchChannel() {
		channelSwitchIndex += 1
		if channelSwitchIndex >= channelSwitches.count {
			channelSwitchIndex = 0
		}
		channels.vectorFloat4Value = channelSwitches[channelSwitchIndex]
//		cropNode.maskNode = maskNode
	}
	public func switchChannelTo(_ index: Int){
		channels.vectorFloat4Value = channelSwitches[index]
	}
	
	func scale(by factor: CGFloat) {
		self.setScale(factor)
	}
	//MARK: DUPLICATE
	func duplicate(at position: CGPoint, oneFrame:Bool = false) -> MagicLoop {
		let duplicate = MagicLoop(textures: self.textures, position: position, settings: self.globalSettings)
		duplicate.frameSkip = self.frameSkip
		duplicate.xScale = self.xScale
		duplicate.yScale = self.yScale
		duplicate.currentFrame = self.currentFrame
		duplicate.isReversed = self.isReversed
		duplicate.spriteNode.blendMode = self.spriteNode.blendMode
		// Set initial alpha to 0
//		duplicate.spriteNode.alpha = 0.0
//		if(self.isMasked){
//			duplicate.toggleCircularMask()
//		}
		duplicate.channels.vectorFloat4Value = self.channels.vectorFloat4Value
		duplicate.maskRadius.floatValue = self.maskRadius.floatValue
		duplicate.fuzziness.floatValue = self.fuzziness.floatValue
		duplicate.maskCenter.vectorFloat2Value = self.maskCenter.vectorFloat2Value
		duplicate.zoom.vectorFloat2Value = self.zoom.vectorFloat2Value
		duplicate.positionRecord = Array(self.positionRecord)
		duplicate.scaleRecord = Array(self.scaleRecord)
		duplicate.rotationRecord = Array(self.rotationRecord)
		duplicate.trueScale = self.trueScale
		duplicate.timeOffset = self.timeOffset
		duplicate.offset = self.offset
		duplicate.updateFrameSkip = self.updateFrameSkip
		duplicate.frameCounter = self.frameCounter
		
		duplicate.zRotation = self.zRotation
		duplicate.trueRotation = self.trueRotation
		duplicate.channelSwitchIndex = self.channelSwitchIndex
		duplicate.targetFps = self.targetFps
		duplicate.targetDelta = self.targetDelta
//		duplicate.switchChannelTo(self.channelSwitchIndex)
		duplicate.playhead = self.playhead
//		duplicate.debugOverlay?.isHidden = ((self.debugOverlay?.isHidden) != nil)
		// Run fade in action
//		let fadeInAction = SKAction.fadeIn(withDuration: 0.3)
//		duplicate.spriteNode.run(fadeInAction)
		
		return duplicate
	}
	
	//MARK: UPRATE
	func update(currentTime: TimeInterval, recording:Bool = false) {
		if textures.isEmpty {
			return
		}
		delta = currentTime - lastUpdateTime
		lastUpdateTime = currentTime
		
//		targetDelta = 1.0/targetFps
		fps = 1.0 / targetDelta
		
//		if ((currentTime - lastChangedFrameTime) >= targetDelta || recording) {
//			lastChangedFrameTime = currentTime
//			fps = 1.0 / (currentTime - lastChangedFrameTime)
//		}
//			currentFrame = (currentFrame + (isReversed ? -1 : 1) + textures.count) % textures.count
		loopDuration = Double(self.totalFrames) * targetDelta
		var framesPlayhead:CGFloat
		timeOffset = loopDuration * self.offset// * self.globalSettings.offsetRatio
		if !freeze {
			frameCounter += 1
			if frameCounter > updateFrameSkip {
				frameCounter = 0
				currentFrame-=frameSkip
			}
			
//			if isReversed{
//				
//			}
//			else{
//				currentFrame+=frameSkip
//			}
			playhead = ((currentTime + timeOffset) / loopDuration).truncatingRemainder(dividingBy: 1.0)
		}
		if isReversed {
			playhead = 1-playhead//(currentTime / loopDuration ).truncatingRemainder(dividingBy: 1.0)
		}
		
		framesPlayhead = ((2-sin(playhead * Double.tau * 10))/2*0.2 + playhead + timeOffset).truncatingRemainder(dividingBy: 1.0)
		framesPlayhead = playhead
		//			framesPlayhead = ((2-sin((currentTime) / loopDuration * Double.tau * 10))/2*0.3+(currentTime + timeOffset) / loopDuration).truncatingRemainder(dividingBy: 1.0)



			//			playhead = ((2-sin((currentTime) / loopDuration * Double.tau * 20))/2*0.2+(currentTime + timeOffset) / loopDuration).truncatingRemainder(dividingBy: 1.0)
			//			playhead = ((2-sin(currentTime / loopDuration * Double.tau * 2 + timeOffset))/2).truncatingRemainder(dividingBy: 1.0)
//			framesPlayhead = ((1 + sin((currentTime + timeOffset) / loopDuration * Double.tau-Double.pi/2))/2).truncatingRemainder(dividingBy: 1.0)
//		fuzziness.floatValue = Float(playhead)
		
		if currentFrame>self.totalFrames-1 {
			currentFrame=0
		}
		else if currentFrame < 0 {
			currentFrame=self.totalFrames-1
		}
//			print("real frame \(currentFrame)")
		var filmFrame = Int(framesPlayhead * floor(Double(totalFrames)))
//		filmFrame = currentFrame
		currentFrame = filmFrame
		if(textures.count>1){
			spriteNode.texture = textures[filmFrame]
		}
		
		if(recording){
//				positionRecord[currentFrame].x = position.x
		}
		if !(physicsBody?.isDynamic ?? false) {
			self.xScale = self.trueScale.x + scaleRecord[currentFrame].x
			self.yScale = self.trueScale.y + scaleRecord[currentFrame].y
			self.position.x = self.truePosition.x+positionRecord[currentFrame].x
			self.position.y = self.truePosition.y+positionRecord[currentFrame].y
			self.zRotation = self.trueRotation+rotationRecord[currentFrame]
		}
//		}
		updateDebugOverlay()
	}
	
	
	
	func update_(currentTime: TimeInterval) {
		if textures.isEmpty {
			return
		}
		if lastUpdateTime == 0 {
			lastUpdateTime = currentTime
		}
		frameCounter += 1
		
		// Ensure frameSkip is valid (greater than or equal to 0)
		let effectiveFrameSkip = max(frameSkip, 0)
		
		// Only update the texture if the effective frame counter reaches the frame skip value
		if effectiveFrameSkip == 0 || frameCounter % (effectiveFrameSkip + 1) == 0 {
			let delta = currentTime - lastUpdateTime
			fps = round(1 / delta)
			currentFrame = (currentFrame + (isReversed ? -1 : 1) + textures.count) % textures.count
			spriteNode.texture = textures[currentFrame]
			lastUpdateTime = currentTime
			self.xScale = self.trueScale.x + scaleRecord[currentFrame].x
			self.yScale = self.trueScale.y + scaleRecord[currentFrame].y
			self.position.x=self.truePosition.x+positionRecord[currentFrame].x
			self.position.y=self.truePosition.y+positionRecord[currentFrame].y
			
		}
		

		updateDebugOverlay()
	}
	
	func reversePlayback() {
		if isReversed{
			
//			timeOffset -= playhead
		}
		else {
//			timeOffset += playhead - (1-playhead)
		}
		isReversed = !isReversed
		
	}
	
	private func createDebugOverlay() {
		debugOverlay = SKNode()
		currentFrameLabel = SKLabelNode(fontNamed: "Courier")
		currentFrameLabel?.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.right
		currentFrameLabel?.fontSize = 32
		currentFrameLabel?.fontColor = .cyan
		currentFrameLabel?.position = CGPoint(x: -0, y: -spriteNode.size.height / 2 + 40)
		debugOverlay?.addChild(currentFrameLabel!)
		
		
		fpsLabel = SKLabelNode(fontNamed: "Courier")
		fpsLabel?.blendMode = .screen
		fpsLabel?.fontSize = 62
		fpsLabel?.fontColor = .cyan
		fpsLabel?.position = CGPoint(x: self.spriteNode.size.width/2-50,
									 y: spriteNode.size.height / 2 - 50)
		debugOverlay?.addChild(fpsLabel!)
		
		timeLabel = SKLabelNode(fontNamed: "Courier")
		timeLabel?.fontSize = 32
		timeLabel?.fontColor = .cyan
		timeLabel?.position = CGPoint(x: self.spriteNode.size.width/2-150,
									 y: -100)
		debugOverlay?.addChild(timeLabel!)
		
		progressBar = SKShapeNode(rectOf: CGSize(width: spriteNode.size.width, height: spriteNode.size.height))
		progressBar?.fillColor = .black
		progressBar?.alpha = 0.5
		progressBar?.lineWidth = 0
		progressBar?.strokeColor = .red
		progressBar?.position = CGPoint(x: -spriteNode.size.width / 2, y: 0)
		debugOverlay?.addChild(progressBar!)
		
		outline = SKShapeNode(rectOf: CGSize(width: spriteNode.size.width, height: spriteNode.size.height))
		outline?.lineWidth = 2
		outline?.strokeColor = .black
		debugOverlay?.addChild(outline!)
		
		debugOverlay?.isHidden = true
		addChild(debugOverlay!)
		debugOverlay?.zPosition = 1
	}
	
	private func updateDebugOverlay() {
		if(frameCounter % 10 == 0){
			fpsLabel?.text = String(format: "%.1f", fps)
		}
		let t = String(" \(String(format:"%.3f",CGFloat(currentFrame)*targetDelta)) / \(String(format: "%.3f", Float(totalFrames)*Float(targetDelta)))")
		timeLabel?.text = t
	
		currentFrameLabel?.text = String("\(currentFrame)/\(totalFrames)")
		let progress = CGFloat(currentFrame) / CGFloat(totalFrames)
		progressBar?.xScale = progress
		progressBar?.position.x = spriteNode.size.width / 2 * progress - spriteNode.size.width/2
	}
	
	public func toggleCircularMask() {
		if isMasked {
			maskRadius.floatValue = 2.0
		} else {
			maskRadius.floatValue = 0.5
		}
		isMasked.toggle()
		print(isMasked)
	}
	public func toggleDebugOverlay() {
		debugOverlay?.isHidden.toggle()
	}
	
}
