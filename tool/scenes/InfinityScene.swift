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


class InfinityScene : SKScene, SKPhysicsContactDelegate{
	var counter = 0
	var brushPos = CGPoint()
	var rotSpeed = 2.0
	override func didMove(to view: SKView) {
		self.backgroundColor = SKColor.white
		physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
		physicsWorld.contactDelegate = self
		let timer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { timer in
			self.counter += 1
//			if self.counter > 100 {
//				timer.invalidate()
//			}
			let a = -CGFloat(self.counter)*0.05
			let radius = self.size.height*0.3+sin(a*10)*100//CGFloat.random(in:self.size.height*0.3..<self.size.height*0.3+50)
			self.brushPos.x = self.size.width/2+cos(a)*self.size.width/4
			self.brushPos.y = self.size.height*0.70+sin(a*2)*100
			let w = (self.size.width + self.size.height) * 0.002 + CGFloat.random(in: 0...20)
			let shape = CustomBox(size: w)
			shape.position = self.brushPos
//			shape.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: CGFloat.random(in: 1...3))))
//			shape.physicsBody?.categoryBitMask = 0b0001
//			shape.physicsBody?.collisionBitMask = 0b0001
			self.addChild(shape)
//			if let shapeClone = shape?.copy() as SKShapeNode? {
//				shapeClone.position = self.brushPos
//			}
		}
		
	}
	func didBegin(_ contact: SKPhysicsContact) {
		if let nodeA = contact.bodyA.node as? CustomBox {
			if nodeA.special{
				if let nodeB = contact.bodyB.node as? CustomBox {
					if !nodeB.special {
						nodeB.turnSpecial(nodeA.infColor)
					}
				}
			}

		}
		if let nodeB = contact.bodyB.node as? CustomBox {
			if nodeB.special{
				if let nodeA = contact.bodyA.node as? CustomBox {
					if !nodeA.special {
						nodeA.turnSpecial(nodeB.infColor)
					}
				}
			}
		}
	}
	override func mouseDown(with event: NSEvent) {
		print(event.location(in: self))
	}
	
	override func mouseDragged(with event: NSEvent) {
		print(event.location(in: self))
	}
	
	override func mouseUp(with event: NSEvent) {
		print(event.location(in: self))
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

class CustomBox: SKSpriteNode {
	var special: Bool = false
	var infected: Bool = false
	var infColor:SKColor = SKColor.white
	init(size: CGFloat) {
//		super.init()
//		let label = SKLabelNode(text: "('-')")
//		let texture = SKTexture(imageNamed: "what")
		let texture = SKTexture()
		let s = CGSize(width: size, height: size)
		super.init(texture: texture, color: SKColor.black, size: s)
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
		self.color = SKColor.black
		self.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size, height: size))
		self.physicsBody!.contactTestBitMask = 0b0001
		self.physicsBody!.isDynamic = false
		self.xScale = 0
		self.yScale = 0
		self.zRotation = CGFloat.random(in: 0...Double.tau)
		self.run(SKAction.colorize(with: SKColor.white, colorBlendFactor: 1, duration: 15))
		self.run(SKAction.sequence([
			SKAction.scale(to: 2, duration: CGFloat.random(in:0.1...0.3)),
			SKAction.scale(to: 1, duration: CGFloat.random(in:0.1...0.3)),
			SKAction.wait(forDuration: 3, withRange: 1),
			SKAction.run {
				self.physicsBody?.isDynamic = true
				//											shape.fillColor = SKColor.white
			},
			SKAction.wait(forDuration: 16, withRange: 5),
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
