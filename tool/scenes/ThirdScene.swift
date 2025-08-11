//
//  SecondScene.swift
//  tool
//
//  Created by sasha t. on 20.10.2023.
//

import Foundation

//
//  SimpleScene.swift
//  tool
//
//  Created by sasha t. on 18.10.2023.
//

import Foundation
import SwiftUI
import SpriteKit
import CoreMotion


class ThirdScene : SKScene, SKPhysicsContactDelegate{
	var counter = 0
	var brushPos = CGPoint()
	var rotSpeed = 2.0
	var isPressed = false
	var pressPoint = CGPoint()
	var modX = 1.0
	var modY = 1.0
	var oldModX = 1.0
	var oldModY = 1.0
	var label:SKLabelNode?
	override func didMove(to view: SKView) {
		self.backgroundColor = SKColor.black
		physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
		physicsWorld.contactDelegate = self
		let timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
			self.counter += 1
//			if self.counter > 100 {
//				timer.invalidate()
//			}
			let a = -CGFloat(self.counter)*0.5
			self.brushPos.x = self.size.width/2+cos(a*self.modX)*self.size.width/2
			self.brushPos.y = self.size.height/4+sin(a*self.modY)*self.size.width/10
			let w = (self.size.width + self.size.height) * 0.002 + CGFloat.random(in: 0...20)
			let shape = SusBox(size: w)
			shape.position = self.brushPos
			self.addChild(shape)
		}
		self.label = SKLabelNode()
		self.label?.fontColor = .white
		self.label?.isHidden = true
		self.addChild(label!)
		
		let radio:SKShapeNode = SKShapeNode(ellipseOf: CGSize(width:40, height:40))
		radio.position = CGPoint(x: 429, y: 782)
		radio.physicsBody = SKPhysicsBody(circleOfRadius: 20)
		radio.physicsBody!.contactTestBitMask = 0b0001
		radio.physicsBody!.isDynamic = false
		radio.lineWidth = 0
		self.addChild(radio)
	}
	override func update(_ currentTime: TimeInterval) {

	}
//	func didBegin(_ contact: SKPhysicsContact) {
//		if let nodeA = contact.bodyA.node as? SusBox {
//			if nodeA.special{
//				if let nodeB = contact.bodyB.node as? SusBox {
//					if !nodeB.special {
//						nodeB.turnSpecial(nodeA.infColor)
//					}
//				}
//			}
//
//		}
//		if let nodeB = contact.bodyB.node as? SusBox {
//			if nodeB.special{
//				if let nodeA = contact.bodyA.node as? SusBox {
//					if !nodeA.special {
//						nodeA.turnSpecial(nodeB.infColor)
//					}
//				}
//			}
//		}
//	}
	override func mouseDown(with event: NSEvent) {
		isPressed = true
		pressPoint = event.location(in: self)
		oldModX = modX
		oldModY = modY
		self.label?.isHidden = false
		print(pressPoint)
	}
	
	override func mouseDragged(with event: NSEvent) {
		print("dragged \(event.location(in: self))")
		
		if isPressed {
//			let deltaX = event.location(in: self).x - pressPoint.x
//			let deltaY = event.location(in: self).y - pressPoint.y
//			modX = oldModX + deltaX/100
//			modY = oldModY + deltaY/100
//			label?.position = event.location(in: self)
//			label?.text = "\(String(format: "%.2f", modX)) : \(String(format: "%.2f", modY))"
			
//			self.brushPos.x = self.size.width/2+cos(a*self.modX)*self.size.width/2
//			self.brushPos.y = self.size.height/4+sin(a*self.modY)*self.size.width/10
			let w = (self.size.width + self.size.height) * 0.002 + CGFloat.random(in: 0...20)
			let shape = SusBox(size: w)
			shape.position = event.location(in: self)
			self.addChild(shape)
		}
	}
	
	override func mouseUp(with event: NSEvent) {
		self.label?.isHidden = true
		isPressed = false
		print("up \(event.location(in: self))")
	}
	override func didChangeSize(_ oldSize: CGSize) {
			super.didChangeSize(oldSize)
			// Adjust the size of the physics body's bounding box to match the new scene size
			physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
			// You may need to reconfigure the physics body or perform additional operations as needed
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
}

class SusBox: SKSpriteNode {
	var special: Bool = false
	var infected: Bool = false
	var infColor:SKColor = SKColor.black
	init(size: CGFloat) {
//		super.init()
//		let label = SKLabelNode(text: "('-')")
//		let texture = SKTexture(imageNamed: "what")
		let texture = SKTexture()
		let s = CGSize(width: size, height: size)
		super.init(texture: texture, color: SKColor.white, size: s)
		self.colorBlendFactor = 1
//		self.special = CGFloat.random(in: 0.0...1.0) > 0.9
		if self.special{
			
			self.infColor = CGFloat.random(in: 0...1) > 0.3 ? SKColor.cyan : SKColor.red
			self.turnSpecial(self.infColor)
			self.infected = true
		}
		let rect = CGRect(x: -size/2, y: -size/2, width: size, height: size)
		// Customize the node's properties
//		self.path = CGPath(rect: rect, transform: nil)
//		self.lineWidth = 1.0
		self.color = SKColor.white
		self.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size, height: size))
		self.physicsBody!.density = 12
		self.physicsBody!.contactTestBitMask = 0b0001
		self.physicsBody!.isDynamic = false
		self.xScale = 0
		self.yScale = 0
		self.zRotation = CGFloat.random(in: 0...Double.tau)
//		self.run(SKAction.colorize(with: SKColor.black, colorBlendFactor: 1, duration: 15))
		self.run(SKAction.sequence([
			SKAction.scale(to: 2, duration: CGFloat.random(in:0.1...0.3)),
			SKAction.scale(to: 1, duration: CGFloat.random(in:0.1...0.3)),
//			SKAction.wait(forDuration: 3, withRange: 1),
			SKAction.run {
				self.physicsBody?.isDynamic = true
				//											shape.fillColor = SKColor.white
			},
			SKAction.wait(forDuration: 6, withRange: 5),
			SKAction.scale(to: 0, duration: CGFloat.random(in:0.1...0.2)),
			//										 SKAction.scale(to: 0, duration: CGFloat.random(in:0.1...0.2)),
			//										 SKAction.fadeOut(withDuration: 2.05),
			SKAction.removeFromParent()
		]))
//		self.addChild(label)
		// Set the custom variable
//			self.customVariable = customVariable
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	func turnSpecial(_ infectionColor: SKColor) {
		self.special = true
		self.infColor = infectionColor
		self.run(SKAction.sequence([
			SKAction.colorize(with: self.infColor, colorBlendFactor: 1, duration: 5),
			SKAction.run {
				self.special = true
			}
			])
		)
		
//		print("Custom function called.")
		// Add your custom function implementation here
	}
}
