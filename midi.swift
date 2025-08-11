		//MARK: MIDI INPUT
	func handleMIDIPackets(packetList: UnsafePointer<MIDIPacketList>) {
		let packetListPointer = packetList.pointee
		var packet = packetListPointer.packet
		
		for _ in 0..<packetListPointer.numPackets {
			let data = packet.data
			let statusByte = data.0
			let midiStatus = statusByte & 0xF0
			let midiChannel = statusByte & 0x0F
			let note = data.1
			let velocity = data.2
			
			print("Received MIDI message - Status: \(midiStatus), Channel: \(midiChannel), Note: \(note), Velocity: \(velocity)")
			print(data)
			print(data.5)
			let value = CGFloat(velocity)/127
			if midiStatus == 144 {
				
				
				isPainting=true
			}
			if midiStatus == 128 {
				isPainting = false
			}
			if statusByte == 178 {
				mode = note
			}
			if statusByte == 177 { //MARK: FADERS
				if mode == 8 {
					switch note {
					case 1:
						wiggleScale.dx = value
					case 2:
						wiggleScale.dy = value
					case 3:
						brushScaleX = CGFloat(velocity)/127
					case 4:
						brushScaleY = CGFloat(velocity)/127
					default:
						break
					}
				}
				else if mode == 7 {
					print(value)
					switch note {
					case 1:
						maskPosition.x = value
					case 2:
						maskPosition.y = value
					case 3:
						brushZoom.x = value
					case 4:
						brushZoom.y = value
					default:
						break
					}
				}
				else if mode == 6 {
					print(value)
					switch note {
					case 1:
						brushBlue = value
					case 2:
						brushBlue = value
					case 3:
						brushGreen = value
					case 4:
						brushRed = value
					default:
						break
					}
					selectedBrush?.channels.vectorFloat4Value = vector_float4(Float(brushRed)*2.0, Float(brushGreen)*2.0, Float(brushBlue)*2.0, 1)
				}
				else if mode == 5 {
					print(value)
					switch note {
					case 1:
						blue = value
					case 2:
						blue = value
					case 3:
						green = value
					case 4:
						red = value
					default:
						break
					}
					backgroundColor = NSColor(red: red, green: green, blue: blue, alpha: 1)
				}
				
				else if mode == 4 {
					print(value)
					switch note {
					case 1:
						brushBlue = value
					case 2:
						brushBlue = value
					case 3:
						selectedBrush?.frameSkip = Int(value * 30)
					case 4:
						selectedBrush?.updateFrameSkip = Int(value * 30)
					default:
						break
					}
				}
			}
			
			if statusByte == 179 { //MARK: KNOBS
				
				switch note{
				case 0:
					//					brushScale = value
					if velocity == 63 {
//						targetFps -= 1
						
//						selectedBrush?.targetDelta = 1.0/CGFloat(targetFps)
						selectedBrush?.frameSkip-=1
						//						brushRotation+=Double.tau/90
					}
					else if velocity == 65 {
//						targetFps += 1
						selectedBrush?.frameSkip+=1
						
//						selectedBrush?.targetDelta = 1.0/CGFloat(targetFps)
						//						brushRotation-=Double.tau/90
					}
				case 1:
					rotationSpeed = value*5
				case 5:
					brush.y = value * self.frame.height
					
				case 2:
					frequency = value
					//					brushRotation = value * CGFloat.tau
				case 6:
					brushLife = value
				case 3:
					//					maskPosition.x = value
					wiggleFrequency.dx = value*10
				case 7:
					//					maskPosition.y = value
					wiggleFrequency.dy = value*10
				case 4:
					wiggleScale.dx = value
				case 8:
					wiggleScale.dy = value
					
				default:
					break
				}
				
				
				print(brush)
			}
			
			
			packet = MIDIPacketNext(&packet).pointee
		}
	}
	
	
	
	func createVirtualMIDIOutputSource() {
		let status = MIDISourceCreate(midiClient, "ToolMIDIOutputSource" as CFString, &midiOutputSource)
		if status == noErr {
			print("MIDI Output Source created successfully")
		} else {
			print("Error creating MIDI Output Source: \(status)")
		}
	}
	func sendMIDINoteOn(note: UInt8, velocity: UInt8, channel: UInt8) {
		var packet = MIDIPacket()
		packet.timeStamp = 0
		packet.length = 3
		packet.data.0 = 0x90 | channel  // Note On message for the specified channel
		packet.data.1 = note            // Note number
		packet.data.2 = velocity        // Velocity
		
		var packetList = MIDIPacketList(numPackets: 1, packet: packet)
		MIDIReceived(midiOutputSource, &packetList)
		print("MIDI Note On sent: Note \(note), Velocity \(velocity), Channel \(channel)")
	}
	
	func createVirtualMIDIInputSource() {
		let status = MIDIInputPortCreateWithBlock(midiClient, "MyMIDIInputPort" as CFString, &midiInputPort) { packetList, _ in
			self.handleMIDIPackets(packetList: packetList)
		}
		
		if status == noErr {
			print("MIDI Input Port created successfully")
		} else {
			print("Error creating MIDI Input Port: \(status)")
		}
	}
	
	func connectMIDISource() {
		let sourceCount = MIDIGetNumberOfSources()
		for i in 0..<sourceCount {
			let midiSource = MIDIGetSource(i)
			var endpointName: Unmanaged<CFString>?
			MIDIObjectGetStringProperty(midiSource, kMIDIPropertyName, &endpointName)
			
			if let name = endpointName?.takeRetainedValue() as String?, name == "MIDI" {
				let statusConnect = MIDIPortConnectSource(midiInputPort, midiSource, nil)
				if statusConnect == noErr {
					print("Connected to \(name)")
				} else {
					print("Error connecting to \(name): \(statusConnect)")
				}
			}
		}
	}
	
	
	
	
	
	func createVirtualMIDIDestination() {
		let status = MIDIDestinationCreateWithBlock(midiClient, "ToolMIDIDestination" as CFString, &midiDestination) { packetList, _ in
			self.handleMIDIPackets(packetList: packetList)
		}
		
		if status == noErr {
			print("MIDI Destination created successfully")
		} else {
			print("Error creating MIDI Destination: \(status)")
		}
	}
	func createMIDIClient() {
		let status = MIDIClientCreate("ToolMIDIClient" as CFString, nil, nil, &midiClient)
		if status == noErr {
			print("MIDI Client created successfully")
		} else {
			print("Error creating MIDI Client: \(status)")
		}
	}
	func setupMIDI() {
		createMIDIClient()
		createVirtualMIDIInputSource()
		createVirtualMIDIOutputSource()
		createVirtualMIDIDestination()
		connectMIDISource()
		let sourceCount = MIDIGetNumberOfSources()
		print("Number of MIDI sources: \(sourceCount)")
		
		if sourceCount > 0 {
			let source = MIDIGetSource(0)
			let statusConnect = MIDIPortConnectSource(midiInputPort, source, nil)
			if statusConnect == noErr {
				print("MIDI Source connected successfully")
				for i in 0..<sourceCount {
					let midiSource = MIDIGetSource(i)
					var endpointName: Unmanaged<CFString>?
					MIDIObjectGetStringProperty(midiSource, kMIDIPropertyName, &endpointName)
					if let name = endpointName?.takeRetainedValue() {
						print("MIDI Source \(i): \(name)")
					}
				}
			} else {
				print("Error connecting to MIDI Source: \(statusConnect)")
			}
		} else {
			print("No MIDI sources available")
		}
		listMIDIOutputSources()
		
	}
	
	func listMIDIOutputSources() {
		let destinationCount = MIDIGetNumberOfDestinations()
		print("Number of MIDI destinations: \(destinationCount)")
		
		for i in 0..<destinationCount {
			let destination = MIDIGetDestination(i)
			var endpointName: Unmanaged<CFString>?
			MIDIObjectGetStringProperty(destination, kMIDIPropertyName, &endpointName)
			if let name = endpointName?.takeRetainedValue() {
				print("MIDI Destination \(i): \(name)")
			}
		}
	}
	func cleanupMIDI() {
		MIDIPortDisconnectSource(midiInputPort, MIDIGetSource(0))
		MIDIClientDispose(midiClient)
	}